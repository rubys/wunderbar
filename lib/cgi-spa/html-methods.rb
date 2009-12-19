# smart style, knows that the content is indented text/data
def $x.style!(text)
  text.slice! /^\n/
  text.slice! /[ ]+\z/
  $x.style :type => "text/css" do
    if $XHTML
      indented_text! text
    else
      indented_data! text
    end
  end
end

# smart script, knows that the content is indented text/data
def $x.script!(text)
  text.slice! /^\n/
  text.slice! /[ ]+\z/
  $x.script :lang => "text/javascript" do
    if $XHTML
      indented_text! text
    else
      indented_data! text
    end
  end
end
