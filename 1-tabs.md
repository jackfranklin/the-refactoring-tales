# Tale 1: Terrible Tabs

One of the most common things any new jQuery user will try to do is build some basic HTML tabs. It's like the initiation into the jQuery world (not quite, that's carousels, which are next up) and it serves as a good starting point to show you the first refactoring.

Here's a JavaScript function called `tabularize` which, as you might expect, is a small function for creating a tabbed interface.

```js
var tabularize = function() {
  var active = location.hash;
  if(active) {
    $(".tabs").children("div").hide();
    $(active).show();
    $(".active").removeClass("active");
    $(".tab-link").each(function() {
      if($(this).attr("href") === active) {
        $(this).parent().addClass("active");
      }
    });
  }
  $(".tabs").find(".tab-link").click(function() {
    $(".tabs").children("div").hide();
    $($(this).attr("href")).show();
    $(".active").removeClass("active");
    $(this).parent().addClass("active");
    return false;
  });
};
```

To help you put this together, here is the HTML that the code is applied to. We won't be looking at the HTML here, just the code, but this will help with picturing how it all works.

```js
<div class="tabs">
  <ul>
    <li class="active"><a href="#tab1" class="tab-link">Tab 1</a></li>
    <li><a href="#tab2" class="tab-link">Tab 2</a></li>
    <li><a href="#tab3" class="tab-link">Tab 3</a></li>
  </ul>
  <div id="tab1">
    <h3>Tab 1</h3>
    <p>Lorem ipsum dolor sit amet</p>
  </div>
  <div id="tab2">
    <h3>Tab 2</h3>
    <p>Lorem ipsum dolor sit amet</p>
  </div>
  <div id="tab3">
    <h3>Tab 3</h3>
    <p>Lorem ipsum dolor sit amet</p>
  </div>
</div>
<script>
  $(tabularize);
</script>
```

There's a fair bit wrong with the JavaScript above, but it's not neccessarily bad code. It performs the tasks that are required of it. There are a couple of bugs, but as refactorers, we are not here to change the behaviour of the code. It passes the tests (in the introduction we discussed how every refactoring must be backed by tests) and our aim is to change the design, not the behaviour, and pass all the tests. I won't show the tests, as they distract from the main purpose, but rest assured I did have them when making the changes I'm about to talk through and I was careful to keep them passing.

## Reuse of Selectors
The key to refactoring is to make the smallest steps you possibly can. The first problem I'd like to tackle is the reuse of selectors.

```js
var active = location.hash;
if(active) {
  $(".tabs").children("div").hide();
  $(active).show();
  $(".active").removeClass("active");
  $(".tab-link").each(function() {
    if($(this).attr("href") === active) {
      $(this).parent().addClass("active");
    }
  });
}
$(".tabs").find(".tab-link").click(function() {
  $(".tabs").children("div").hide();
  $($(this).attr("href")).show();
  $(".active").removeClass("active");
  $(this).parent().addClass("active");
  return false;
});
```

Looking over the code again, you can see a few selectors that crop up again and again:

- `$(".tabs")`
- `$(".tabs").children("div")`
- `$(".tab-link")`

So let's make the change. We'll replace them, but do it _one at a time_, and run the tests _after every change_. This might seem excessive, but it really is key to this process.

Firstly, I'll store a reference to `$(".tabs")`:

```js
var tabsWrapper = $(".tabs");
```

And then I can replace every occurence of `$(".tabs")` with `tabsWrapper`:

```js
var tabsWrapper = $(".tabs");
var active = location.hash;
if(active) {
  tabsWrapper.children("div").hide();
  $(active).show();
  $(".active").removeClass("active");
  $(".tab-link").each(function() {
    if($(this).attr("href") === active) {
      $(this).parent().addClass("active");
    }
  });
}
tabsWrapper.find(".tab-link").click(function() {
  tabsWrapper.children("div").hide();
  $($(this).attr("href")).show();
  $(".active").removeClass("active");
  $(this).parent().addClass("active");
  return false;
});
```

Now that's done and everything is passing, I can repeat the step with `$(".tabs").children("div")`:

```js
var tabsWrapper = $(".tabs");
var tabs = tabsWrapper.children("div");
var active = location.hash;
if(active) {
  tabs.hide();
  $(active).show();
  $(".active").removeClass("active");
  $(".tab-link").each(function() {
    if($(this).attr("href") === active) {
      $(this).parent().addClass("active");
    }
  });
}
tabsWrapper.find(".tab-link").click(function() {
  tabs.hide();
  $($(this).attr("href")).show();
  $(".active").removeClass("active");
  $(this).parent().addClass("active");
  return false;
});
```

And finally, deal with `$(".tab-link")`:

```js
var tabsWrapper = $(".tabs");
var tabs = tabsWrapper.children("div");
var tabLinks = tabsWrapper.find(".tab-link");
var active = location.hash;
if(active) {
  tabs.hide();
  $(active).show();
  $(".active").removeClass("active");
  tabLinks.each(function() {
    if($(this).attr("href") === active) {
      $(this).parent().addClass("active");
    }
  });
}
tabLinks.click(function() {
  tabs.hide();
  $($(this).attr("href")).show();
  $(".active").removeClass("active");
  $(this).parent().addClass("active");
  return false;
});
```

And now, even with just that small change in place, our code is improved. We have removed duplication, which in my opinion has given us two big improvements.

1. If any of the selectors change, or our HTML changes, we only have to change those selectors in one place, not multiple.
2. The code is clearer now. If you need to skim and quickly gain an understanding of what the code does, having well named variables in place of complex selectors helps massively.
