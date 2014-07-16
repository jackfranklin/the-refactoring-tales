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

## More Duplication

There's a bit more duplication going on though. If you look through the code, you'll see the string `"active"` present far too many times. What if the class we gave the active tab had to change? Right now, we're looking at __five__ occurences of it. Wouldn't it be better if that was just one?

Let's introduce an `activeClass` variable to deal with this:

```js
var tabsWrapper = $(".tabs");
var tabs = tabsWrapper.children("div");
var tabLinks = tabsWrapper.find(".tab-link");
var activeClass = "active";

var active = location.hash;
if(active) {
  tabs.hide();
  $(active).show();
  $("." + activeClass).removeClass(activeClass);
  tabLinks.each(function() {
    if($(this).attr("href") === active) {
      $(this).parent().addClass(activeClass);
    }
  });
}
tabLinks.click(function() {
  tabs.hide();
  $($(this).attr("href")).show();
  $("." + activeClass).removeClass(activeClass);
  $(this).parent().addClass(activeClass);
  return false;
});
```

That's a good step to take, but in the midst of doing this you might have spotted some more duplication. Take a look at these two code blocks. They look pretty similar to me:

```js
$("." + activeClass).removeClass(activeClass);
tabLinks.each(function() {
  if($(this).attr("href") === active) {
    $(this).parent().addClass(activeClass);
  }
});
```

```js
$("." + activeClass).removeClass(activeClass);
$(this).parent().addClass(activeClass);
```

The first is slightly different, because it has to loop over the links to find the right element to work with, but both of these blocks are performing the same piece of work:

1. Find the current element with the active class, and remove the active class.
2. Take this new element's parent, and add the active class.

When we have more than one block of code doing the same thing we can abstract them out into a function. Let's do that now:

```js
var activateLink = function(elem) {
  $("." + activeClass).removeClass(activeClass);
  $(elem).addClass(activeClass);
};
```

The `activateLink` function takes an element and adds the active class to it once it's first removed the active class from any other element that might have it. Now we have this function, we can use it in replace of the code we looked at previously. We'll do this change one at a time. Firstly, we can edit the code within the `tabLinks.click` handler:

```js
var tabsWrapper = $(".tabs");
var tabs = tabsWrapper.children("div");
var tabLinks = tabsWrapper.find(".tab-link");
var activeClass = "active";
var activateLink = function(elem) {
  $("." + activeClass).removeClass(activeClass);
  $(elem).addClass(activeClass);
};

var active = location.hash;
if(active) {
  tabs.hide();
  $(active).show();
  $("." + activeClass).removeClass(activeClass);
  tabLinks.each(function() {
    if($(this).attr("href") === active) {
      $(this).parent().addClass(activeClass);
    }
  });
}
tabLinks.click(function() {
  tabs.hide();
  $($(this).attr("href")).show();
  activateLink($(this).parent());
  return false;
});
```

Now all we have to do is pass `$(this).parent()`, which is the element we want to gain the active class, into our `activateLink` function, and it does the rest. We can now swap our function in in place of the code in the `if(active) {}` block:

```js
var tabsWrapper = $(".tabs");
var tabs = tabsWrapper.children("div");
var tabLinks = tabsWrapper.find(".tab-link");
var activeClass = "active";
var activateLink = function(elem) {
  $("." + activeClass).removeClass(activeClass);
  $(elem).addClass(activeClass);
};

var active = location.hash;
if(active) {
  tabs.hide();
  $(active).show();
  tabLinks.each(function() {
    if($(this).attr("href") === active) {
      activateLink($(this).parent());
    }
  });
}
tabLinks.click(function() {
  tabs.hide();
  $($(this).attr("href")).show();
  activateLink($(this).parent());
  return false;
});
```

Abstracting code out into functions is one of the easiest and most effective ways to make a block of code more maintainable. Functions are inherently self documenting, a well named function can tell you in one quick skim exactly what its function is, and what it does. As a new developer coming to the above block of code, I can understand the `activateLink` function's effect _without looking at the code within it_. Being able to skim a block of code and gain an understanding without having to look at detailed implementation is a fantastic thing as a developer.

## Step Back

We are far from done with these tabs, but I want you to notice how, even after just a couple of small changes, the code is now already in an improved position than when we picked it up. We have removed duplication of selectors and code, and made the code more self documenting and readable along the way. When refactoring, you should be in a position to stop the refactoring at any point, and move onto something else. If this was a real project, and suddenly I was called to an urgent bug in another project, I could commit this code now and still have improved it. You should never find yourself in such a mess that you can't put the code down and come back later. This is vital to successful refactorings: keep them small and contained.
