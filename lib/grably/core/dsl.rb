module Grably
  # Contains custom Grably DSL definitions.
  module DSL
    def grab(module_call, as:, &block)
      executor = Grably.server.schedule(module_call)

      last_desc = Rake.application.last_description
      desc module_call.pretty_print unless last_desc
      task(as) do |t|
        products = executor.call(t.task_dir)
        block ? yield(t, products) : (t << products)
      end
    end
  end
end
