#Gives you easy syntax to use ABongo in your views.

class Abongo
  module ViewHelper

    def ab_test(test_name, alternatives = nil, options = {}, &block)
      @choices ||= {}
      unless @choices[test_name]
        if (Abongo.options[:enable_specification] && !params[test_name].nil?)
          @choices[test_name] = params[test_name]
        elsif (Abongo.options[:enable_override_in_session] && !session[test_name].nil?)
          @choices[test_name] = session[test_name]
        elsif (Abongo.options[:enable_selection] && !params[test_name].nil?)
          @choices[test_name] = Abongo.parse_alternatives(alternatives)[params[test_name].to_i]
        elsif (alternatives.nil?)
          begin
            @choices[test_name] = Abongo.flip(test_name, options)
          rescue
            if Abongo.options[:failsafe]
              @choices[test_name] = true
            else
              raise
            end
          end
        else
          begin
            @choices[test_name] = Abongo.test(test_name, alternatives, options)
          rescue
            if Abongo.options[:failsafe]
              @choices[test_name] = Abongo.parse_alternatives(alternatives).first
            else
              raise
            end
          end
        end
      end
      
      if block
        content_tag = capture(@choices[test_name], &block)
        Rails::VERSION::MAJOR <= 2 && block_called_from_erb?(block) ? concat(content_tag) : content_tag
      else
        @choices[test_name]
      end
    end
    
    def bongo!(test_name, options = {})
      begin
        Abongo.bongo!(test_name, options)
      rescue
        if Abongo.options[:failsafe]
          return
        else
          raise
        end
      end
    end
    
    #This causes an AJAX post against the URL.  That URL should call Abongo.human!
    #This guarantees that anyone calling Abongo.human! is capable of at least minimal Javascript execution, and thus is (probably) not a robot.
    def include_humanizing_javascript(url = "/abongo_mark_human", style = :prototype)
      begin
        return if Abongo.is_human?
      rescue
        if Abongo.options[:failsafe]
        else
          raise
        end
      end
      
      script = nil
      if (style == :prototype)
        script = "var a=Math.floor(Math.random()*11); var b=Math.floor(Math.random()*11);var x=new Ajax.Request('#{url}', {parameters:{a: a, b: b, c: a+b}})"
      elsif (style == :jquery)
        script = "jQuery(document).ready(function(){var a=Math.floor(Math.random()*11); var b=Math.floor(Math.random()*11);var x=jQuery.post('#{url}', {a: a, b: b, c: a+b})});"
      end
      script.nil? ? "" : %Q|<script type="text/javascript">#{script}</script>|.html_safe
    end
  end
end
