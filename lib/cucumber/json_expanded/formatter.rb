module Cucumber
  module JsonExpanded
    ##
    # This is similar to the built-in Cucumber JSON formatter except it expands
    # scenario outlines so each row is reported with its result.  Thus, scenario
    # outlines appear similar to regular scenarios in the JSON output.
    #
    # This supports regular mode and "--expand" mode.  In both cases, scenario
    # outline tables are expanded (however the underlying logic for doing the
    # expansion varies greatly).
    #
    # This produces scenario outline JSON that
    # [cucumber-reporting](https://github.com/masterthought/cucumber-reporting)
    # can consume.
    #
    # The expansion is quite a hack and may not be supported in all versions of
    # Cucumber.  Please monitor the following bug for a proper solution to scenario
    # outlines in JSON:
    #   https://github.com/cucumber/gherkin/issues/165
    #
    # Notes:
    #   * When not in "--expand" mode, duration can't be calculated per step.
    #     The duration for the entire feature is appended to the last step.
    #   * Scenario Outlines are still called "Scenario Outlines" even though
    #     they look more like regular Scenarios in the output.
    #   * Argument matches are empty.
    
    class Formatter < Cucumber::Formatter::GherkinFormatterAdapter
      include Cucumber::Formatter::Io

      def initialize(runtime, io, options)
        @io = ensure_io(io, "json")
        super(Gherkin::Formatter::JSONFormatter.new(@io), false)
      end

      def before_feature_element(feature_element)
        @outline_table = nil
        if feature_element.is_a?(Ast::ScenarioOutline)
          @outline = true
          @feature_element = feature_element
        else
          super
        end
      end

      def before_step(step)
        if @outline_table
          table_row = @outline_table.example_rows[@outline_table_row]
          outline_before_step(step, table_row)
        elsif !@outline
          super
        end
      end

      def before_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line)
        if @outline_table
          outline_before_step_result(status, exception)
        elsif !@outline
          super
        end
      end

      def before_examples(examples)
        unless @outline
          super
        end
      end

      def after_step(*args)
        if !@outline || @outline_table
          super
        end
      end

      def before_outline_table(outline_table)
        @outline_table = outline_table
        @outline_table_row = -1
      end

      def after_outline_table(outline_table)
        @outline_table = nil
      end

      def scenario_name(*args)
        if @outline_table
          # Scenario Name is the only way we know we are moving
          # to a new table row in "--expand" mode.
          @outline_table_row += 1
          outline_before_table_row(@feature_element)
        end
      end

      def before_table_row(table_row)
        @table_row_time = Time.now
      end

      ##
      # Output a Scenario Outline element for each table row.  In JSON
      # this appears more like a scenario than a scenario outline.
      # This is only called when not in "--expand" mode.
      def after_table_row(table_row)
        # XXX: Hack to get step collection
        step_invocations = table_row.instance_variable_get('@step_invocations')

        if step_invocations
          # Add a new "scenario" for this row
          outline_before_table_row(@feature_element)

          step_invocations.each do |step|
            outline_before_step(step, table_row)
            outline_before_step_result(step.status, step.exception)
          end

          # We don't have enough hooks to get duration for each step, so
          # just report the total duration at the end of the execution
          step_finish = (Time.now - @table_row_time)
          @gf.append_duration(step_finish)
        end
      end

      private

      def outline_before_table_row(feature_element)
        @gf.scenario_outline(feature_element.gherkin_statement)
      end

      def outline_before_step(step, table_row)
        @gf.step(step_from_table(step, table_row))

        # TODO: We don't actually populate the match.arguments array.
        # Should we try to emulate a step_match?
        # We don't want to use outline_args as we've replaced the
        # placeholders with actual values.
        match = Gherkin::Formatter::Model::Match.new([], nil)
        @gf.match(match)

        @step_time = Time.now
      end

      def outline_before_step_result(status, exception)
        error_message = exception ? "#{exception.message} (#{exception.class})\n#{exception.backtrace.join("\n")}" : nil
        @gf.result(Gherkin::Formatter::Model::Result.new(status, nil, error_message))
      end

      # Replaces table cells in the name of the given step.
      #
      # @return Gherkin::Formatter::Model::Step with
      def step_from_table(step, table_row)
        # XXX: Hack to change the name from:
        #   "Given two numbers <number_1> and <number_2>"
        # to:
        #   "Given two number 1 and 2"
        # We actually instantiate a separate Gherkin::Formatter::Model::Step
        # to avoid corrupting the original step.
        name = step.gherkin_statement.name.dup
        table_row.to_hash.each do |key, val|
          name.gsub!("<#{key}>", val)
        end
        Gherkin::Formatter::Model::Step.new(
          step.gherkin_statement.comments,
          step.gherkin_statement.keyword,
          name,
          step.gherkin_statement.line,
          step.gherkin_statement.rows,
          step.gherkin_statement.doc_string
        )
      end
      
    end
  end
end