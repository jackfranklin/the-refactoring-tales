# Tale 1: Terrible Tabs

One of the most common things any new jQuery user will try to do is build some basic HTML tabs. It's like the initiation into the jQuery world (not quite, that's carousels, which are next up) and it serves as a good starting point to show you the first refactoring.

Here's a JavaScript function called `tabularize` which, as you might expect, is a small function for creating a tabbed interface.

```javascript
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

```javascript
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

```javascript
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

```javascript
var tabsWrapper = $(".tabs");
```

And then I can replace every occurence of `$(".tabs")` with `tabsWrapper`:

```javascript
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

```javascript
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

```javascript
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

```javascript
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

```javascript
$("." + activeClass).removeClass(activeClass);
tabLinks.each(function() {
  if($(this).attr("href") === active) {
    $(this).parent().addClass(activeClass);
  }
});
```

```javascript
$("." + activeClass).removeClass(activeClass);
$(this).parent().addClass(activeClass);
```

The first is slightly different, because it has to loop over the links to find the right element to work with, but both of these blocks are performing the same piece of work:

1. Find the current element with the active class, and remove the active class.
2. Take this new element's parent, and add the active class.

When we have more than one block of code doing the same thing we can abstract them out into a function. Let's do that now:

```javascript
var activateLink = function(elem) {
  $("." + activeClass).removeClass(activeClass);
  $(elem).addClass(activeClass);
};
```

The `activateLink` function takes an element and adds the active class to it once it's first removed the active class from any other element that might have it. Now we have this function, we can use it in replace of the code we looked at previously. We'll do this change one at a time. Firstly, we can edit the code within the `tabLinks.click` handler:

```javascript
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

```javascript
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

## Higher level duplication

The code we've been working with has two blocks:

```javascript
if(active) {
  // do tab things
};

tabLinks.click(function() {
  // do tab things
};
```

Although it doesn't look like it at a glance, there's a lot of duplication going on - both those blocks of code perform basically the same task. This can be sometimes hard to spot, as it can be hidden behind code that doesn't immediately look the same.

```javascript
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

Now I've given you the primer, take another look over the code above. Notice how both blocks do the same thing:

- hide all the tabs
- find and show a specific tab
- update the link for that tab with a new class

The duplication is obscured somewhat because of the need for the `tabLinks.each` in the first block, but this doesn't mean that we can't abstract that duplication into a function.

Sticking with our mantra of making small steps, let's first make a function that shows a specific tab. Sticking with the naming conventions, we'll call it `activateTab`:

```javascript
var activateTab = function(tabSelector) {
  tabs.hide();
  $(tabSelector).show();
};
```

This function takes a selector and shows it, after hiding all of the tabs first. We can now use this in both the `if(active)` block and in the event handler:

```javascript
var tabsWrapper = $(".tabs");
var tabs = tabsWrapper.children("div");
var tabLinks = tabsWrapper.find(".tab-link");
var activeClass = "active";

var activateLink = function(elem) {
  $("." + activeClass).removeClass(activeClass);
  $(elem).addClass(activeClass);
};

var activateTab = function(tabSelector) {
  tabs.hide();
  $(tabSelector).show();
};

var active = location.hash;
if(active) {
  activateTab(active);
  tabLinks.each(function() {
    if($(this).attr("href") === active) {
      activateLink($(this).parent());
    }
  });
}
tabLinks.click(function() {
  activateTab($(this).attr("href"));
  activateLink($(this).parent());
  return false;
});
```

We're really motoring now. Notice how the tabLinks event handler simply calls two other functions, and has very little in it. This is a good sign that we're on the right tracks. [Ben Orenstein](http://codeulate.com/), a developer who speaks a huge amount on refactoring, says that a function with one line inside is superior to a function with two lines, which in turn is superior to a function with three lines, and so on. [Sandi Metz](http://www.sandimetz.com/), a well known Ruby developer, defined a [set of rules](http://robots.thoughtbot.com/sandi-metz-rules-for-developers) that help when building large projects, one of which is: "Methods can be no longer than five lines of code.". Regardless of if you think five is a good or bad number for that rule, the point stands: short, small functions are nearly always preferable to large ones. Keep functions small and compose larger functions out of calling lots of little ones.

Before we continue, notice again how if we wanted to stop now, we could. It's so important to not let yourself get down a huge rabbit hole of refactoring.

## Merging the branches 

Right now we have two branches in our code, the `if(active)` part and the event handler. I'd really like to try and get these into one, or at least make the branches as small as possible. Right now they still have duplication, they noth call `activateTab` and `activateLink`. I'd really like to abstract that out into another function, but right now the obvious step isn't that obvious. Sometimes you'll reach a point like this when you're coding, where you know waht you need to do or want to do, but the step isn't obvious. Often you'll have to make another change, to make the new change easier. In their book [Refactoring](http://refactoring.com/), Martin Fowler and Kent Beck put this nicely:

> When you find you have to add a feature to a program, and the program's code is not structured in a convenient way to add the feature, first refactor the program to make it easy to add the feature, then add the feature.

Although this quote talks about new features, what it efffectively says is that if you need to make a change, but that change is proving tough to make, make other changes such that your original change is easy.

I realised after some thinking that the bit of code making this change difficult is this bit:

```javascript
tabLinks.each(function() {
  if($(this).attr("href") === active) {
    activateLink($(this).parent());
  }
});
```

The fact that we have to loop over means we can't just abstract out as easily. Instead of the `each`, we can instead use jQuery's `filter` method:

```javascript
var link = tabLinks.filter(function() { 
  return $(this).attr("href") === active;
}.parent());
activateLink(link);
```

We now filter over the tab links, looking for the one that matches the `active` hash, and get at the item that way instead. I can store the result of that to a variable, and then pass `activateLink` that element. Adding that change into our code gives us:

```javascript
var tabsWrapper = $(".tabs");
var tabs = tabsWrapper.children("div");
var tabLinks = tabsWrapper.find(".tab-link");
var activeClass = "active";

var activateLink = function(elem) {
  $("." + activeClass).removeClass(activeClass);
  $(elem).addClass(activeClass);
};

var activateTab = function(tabSelector) {
  tabs.hide();
  $(tabSelector).show();
};

var active = location.hash;
if(active) {
  activateTab(active);
  var link = tabLinks.filter(function() { 
    return $(this).attr("href") === active;
  }.parent());
  activateLink(link);
}
tabLinks.click(function() {
  activateTab($(this).attr("href"));
  activateLink($(this).parent());
  return false;
});
```

Now, to see where the next change will come from, we need to examine a bit more closely the `activateLink` and `activateTab` function. Ideally, I'd like to encapsulate these into another function, but to do that we need to see what each function needs as a parameter. `activateTab` just takes a selector and uses that to hide and show what's required, but `activateLink` actually takes in an element. However, if you look closely, you'll note that there is a relationship between the `activateTab` parameter and the `activateLink` parameter. The `activateLink` is the parent of the element whose selector we pass into `activateTab`. So why don't we pass the selector into `activateLink`, and let it find the exact element it needs?

```javascript
var activateLink = function(selector) {
  $("." + activeClass).removeClass(activeClass);
  var elem = tabLinks.filter(function() { 
    return $(this).attr("href") === selector;
  }.parent());
  $(elem).addClass(activeClass);
};
```

With that change, suddenly we can rewrite the two branches of our code to look very similar indeed:

```javascript
if(active) {
  activateTab(active);
  activateLink(active);
}
tabLinks.click(function() {
  activateTab($(this).attr("href"));
  activateLink($(this).attr("href"));
  return false;
});
```

Now we've achieved what we wanted; by performing some intermediate refactorings we now are in a position to deal with the duplication we have in the two branches.

## One method to rule them all

We're going to extract a new method, called `transition`, which will take the selector of the active tab in as its argument, and perform the tasks required. The `transition` method is very simple, it just hands off to `activateTab` and `activateLink`:

```javascript
var transition = function(selector) {
  activateTab(selector);
  activateLink(selector);
};
```

And now we can use that method in our code. In reality I did make this change in two steps, inserting one usage at a time, but I think you get the picture, so I'll show it here as one change. Our new code looks like so:

```javascript
var tabsWrapper = $(".tabs");
var tabs = tabsWrapper.children("div");
var tabLinks = tabsWrapper.find(".tab-link");
var activeClass = "active";

var activateLink = function(elem) {
  $("." + activeClass).removeClass(activeClass);
  $(elem).addClass(activeClass);
};

var activateTab = function(tabSelector) {
  tabs.hide();
  $(tabSelector).show();
};

var transition = function(selector) {
  activateTab(selector);
  activateLink(selector);
};

var active = location.hash;
if(active) {
  transition(active);
}
tabLinks.click(function() {
  transition($(this).attr("href'));
  return false;
});
```

## Reflection

There's certainly more you could do with this code, and it's also far from being the best implementation of tabs around, but I hope you agree with me that the end result is now much nicer than the one we had at the beginning, which is printed below for you to compare.

```javascript
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

By removing duplication and making things clearer, we've ended up with a solution that is more readable, self documenting and maintainable. Notice how at first glance the two different sections of the code looked very different, but after some initial refactorings we found them actually to be near identical. This is a common occurence - often a refactor will open up new possibilities and ways of working, which is another reason to keep your refactorings small and your mind open - an improvement might not be immediately obvious at the beginning.
