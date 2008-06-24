# merb_async_observer - A Merb plugin to make using beanstalkd a cream dream

# Copyright (C) 2007 Philotic Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'merb_async_observer/queue'

CLASSES_TO_EXTEND = [
  ActiveRecord::Base,
  Array,
  Hash,
  Module,
  Numeric,
  Range,
  String,
  Symbol,
]

module Merb::AsyncObserver::Extensions
  def async_send(selector, *args)
    async_send_opts(selector, {}, *args)
  end
  
  def async_send_opts(selector, opts, *args)
    Merb::AsyncObserver::Queue.put_call!(self, selector, opts, args)
  end
end

# make sure we're running inside Merb
if defined?(Merb::Plugins)  
  Merb::BootLoader.before_app_loads do
    # require code that must be loaded before the application
  end
  
  Merb::BootLoader.after_app_loads do
    # code that can be required after the application loads
    CLASSES_TO_EXTEND.each do |c|
      c.send :include, Merb::AsyncObserver::Extensions
    end
    
    HOOKS = [:after_create, :after_update, :after_save]

    class << ActiveRecord::Base
      HOOKS.each do |hook|
        code = %Q{def async_#{hook}(&b) add_async_hook(#{hook.inspect}, b) end}
        class_eval(code, __FILE__, __LINE__ - 1)
      end

      def add_async_hook(hook, block)
        async_hooks[hook] << block
      end

      def async_hooks
        @async_hooks ||= Hash.new do |hash, hook|
          ahook = :"_async_#{hook}"

          # This is for the producer's benefit
          send(hook){|o| async_send(ahook, o)}

          # This is for the worker's benefit
          code = "def #{ahook}(o) run_async_hooks(#{hook.inspect}, o) end"
          instance_eval(code, __FILE__, __LINE__ - 1)

          hash[hook] = []
        end
      end

      def run_async_hooks(hook, o)
        async_hooks[hook].each{|b| b.call(o)}
      end

      def send_to_instance(id, selector, *args)
        x = find_by_id(id)
        x.send(selector, *args) if x
      end

      def async_each_opts(selector, opts, *args)
        min = opts.fetch(:min, minimum(:id))
        max = opts.fetch(:max, maximum(:id))

        (min..max).async_each_opts(self, :send_to_instance, opts, selector, *args)
      end

      def async_each(selector, *args)
        async_each_opts(selector, {}, *args)
      end
    end
  end
  
  Merb::Plugins.add_rakefiles "merb_facebooker/merbtasks"
end

class Range
  DEFAULT_FANOUT_FUZZ = 0
  DEFAULT_FANOUT_DEGREE = 1000

  def split_to(n)
    split_by((size + n - 1) / n) { |group| yield(group) }
  end

  def split_by(n)
    raise ArgumentError.new('invalid slice size') if n < 1
    n -= 1 if !exclude_end?
    i = first
    while member?(i)
      j = [i + n, last].min
      yield(Range.new(i, j, exclude_end?))
      i = j + (exclude_end? ? 0 : 1)
    end
  end

  def size
    last - first + (exclude_end? ? 0 : 1)
  end

  def async_each_opts(rcv, selector, opts, *extra)
    fanout_degree = opts.fetch(:fanout_degree, DEFAULT_FANOUT_DEGREE)
    if size <= fanout_degree
      each {|i| rcv.async_send_opts(selector, opts, i, *extra)}
    else
      fanout_opts = opts.merge(:fuzz => opts.fetch(:fanout_fuzz,
                                                   DEFAULT_FANOUT_FUZZ))
      split_to(fanout_degree) do |subrange|
        subrange.async_send_opts(:async_each_opts, fanout_opts, rcv, selector,
                                 opts, *extra)
      end
    end
  end

  def async_each(rcv, selector, *extra)
    async_each_opts(rcv, selector, {}, *extra)
  end
end
