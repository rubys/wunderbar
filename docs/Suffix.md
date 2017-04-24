_Suffix And Options CheatSheet
===

Wunderbar provides a variety of formatting and attribute helpers to many
output methods.  Here's a cheat sheet showing some output.

<table>
<thead><tr><th>This ruby snippet creates...</th><th>... this html snippet output.</th></thead>
<tr>
<td>

```ruby
_div.outer do
  _div! '_div! "example"'

  _p_ '_p_ "example"'

  _p.id2!.class '_p.id2!.class "example"'
  _div.class.id3! '_div.class.id3! "example"'
  _p!.class.id4! '_p!.class.id4! "example"'
  
  _div_!.ridiculous.id998! '_div_!.ridiculous.id998! "example, class: \'extra\'"', class: 'extra'

  _div_.inner do
    _  '_ "example"'
    _! '_! "example"'
    
    __ '__ "example"'            
  end

  _p? do
    _ %q(_p? do
        _ %q(
          example
          Note that just '_p? "example"' throws NoMethodError: undefined method `call' for nil:NilClass
        )
      end)
  end
  _.tag! :tag
  _.tag! "tag2", '_.tag! "tag2", "example"'
  _.tag! "tag3", class: 'fred' do
    _ %q(
      _.tag! "tag3", class: 'fred' do
        _ %q(
            example ad infinitum
          )
      end)
  end
  _.comment! "_.comment! '_.comment!'"
  _{ "_{ '<code>Markup Import</code>' }" }
  _ << "_ << '<code>Markup Shift</code>'"
  _p_!.ridiculous.id999!.extra attr: 'val' do 
    _ %q(_p_!.ridiculous.id999!.extra attr: 'val' do 
_ %q(
_p_!.ridiculous.id999!.extra attr: 'val' do 
  ad infinitum
end
)
end)
  end
  _div.meta.readthecode! p: ['p_id', 'p_class', 'paragraph content'], div: ['div_id', 'div_class', 'div content'] do |tag, val|
    _.tag! tag, id: val[0], class: val[1]  do
      _ val[2]
    end
  end
end
```

</td>
<td>

```html 
<div class="outer">
  <div>_div! "example"</div>

  <p>_p_ "example"</p>

  <p id="id2" class="class">_p.id2!.class "example"</p>
  <div class="class" id="id3">_div.class.id3! "example"</div>
  <p class="class" id="id4">_p!.class.id4! "example"</p>

  <div class="ridiculous extra" id="id998">_div_!.ridiculous.id998! "example, class: 'extra'"</div>

  <div class="inner">
    _ "example"
_! "example"

    __ "example"
  </div>

  <p>
    _p? do
            _ %q(
              example
              Note that just '_p? "example"' throws NoMethodError: undefined method `call' for nil:NilClass
            )
          end
  </p>
  <tag></tag>
  <tag2>_.tag! "tag2", "example"</tag2>
  <tag3 class="fred">
    _.tag! "tag3", class: 'fred' do
      _ %q(
          example ad infinitum
        )
    end
  </tag3>
  <!-- _.comment! '_.comment!' -->
  _{ '&lt;code&gt;Markup Import&lt;/code&gt;' }
_ << '<code>Markup Shift</code>'

  <p class="ridiculous extra" id="id999" attr="val">_p_!.ridiculous.id999!.extra attr: 'val' do 
_ %q(
_p_!.ridiculous.id999!.extra attr: 'val' do 
ad infinitum
end
)
end</p>

  <div class="meta" id="readthecode">
    <p id="p_id" class="p_class">
      paragraph content
    </p>
    <div id="div_id" class="div_class">
      div content
    </div>
  </div>
</div>
```

</td>
</tr>
</table>
