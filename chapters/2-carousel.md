# Tale 2: Cringey Carousels

In this chapter I want to talk about the value of some "quick wins" - very simple refactorings that, when applied to a codebase, will hugely improve the readability and maintainability of the project, at very little time and effort to yourself. You may find yourself too busy to fully refactor a huge method, but with these small steps you can make large gains quickly.

## The Carousel

I've put together a simple enough jQuery Carousel which boasts the following feature set:

- 'Left' and 'Right' links to navigate the carousel
- Moves automatically every 10 seconds
- If you hit the page with a hash such as `#image2`, it will move the carousel to that image.

Hardily a fully featured carousel but it covers the basic functionality of most carousels I've seen, and those features provide enough scope for me to produce bad code that we can tidy. Take a deep breath and we'll dive in.

First, there's the HTML. Pretty simple and standard really:

```html
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <link rel="stylesheet" href="css/style.css">
  <script src="js/jquery.min.js"></script>
  <script src="js/app.js"></script>
</head>
<body>
  <div class="wrapper">
    <ul>
      <li><img src="http://placekitten.com/300/300" alt="Kitten" /></li>
      <li><img src="http://placekitten.com/300/300" alt="Kitten" /></li>
      <li><img src="http://placekitten.com/300/300" alt="Kitten" /></li>
      <li><img src="http://placekitten.com/300/300" alt="Kitten" /></li>
      <li><img src="http://placekitten.com/300/300" alt="Kitten" /></li>
    </ul>
    <div class="controls">
      <a href="#" class="left">Left</a>
      <a href="#" class="right">Right</a>
      <span></span>
    </div>
  </div>
</body>
</html>
```

There is also some CSS applied to make it look good, but we won't be focusing on that.

Finally, the JavaScript:

```javascript
$(function() {
  if(location.hash && location.hash.indexOf("image") > -1) {
    var number = parseInt(location.hash.charAt(location.hash.length -1));
    $("ul").animate({
      "margin-left": number * -300
    }, function() {
      currentImage = number;
      $(".controls span").text("Current: " + (currentImage + 1));
    });
  }
  var timeout = setTimeout(function() {
    $(".left").trigger("click");
  }, 10000);
  
  var currentImage = 0;
  $(".left").click(function() {
    clearTimeout(timeout);
    if(currentImage == $("li").length - 1) {
      $("ul").animate({
        "margin-left": 0
      }, function() {
        currentImage = 0;
        $(".controls span").text("Current: " + (currentImage + 1));
      });
    } else {
      $("ul").animate({
        "margin-left": "-=300px"
      }, function() {
        currentImage+=1;
        $(".controls span").text("Current: " + (currentImage + 1));
      });
    }
    timeout = setTimeout(function() {
      $(".left").trigger("click");
    }, 10000);
    return false;
  });
  
  $(".right").click(function() {
    clearTimeout(timeout);
    if(currentImage == 0) {
      $("ul").animate({
        "margin-left": ($("li").length - 1) * -300
      }, function() {
        currentImage = $("li").length - 1;
        $(".controls span").text("Current: " + (currentImage + 1));
      });
    } else {
      $("ul").animate({
        "margin-left": "+=300px"
      }, function() {
        currentImage-=1;
        $(".controls span").text("Current: " + (currentImage + 1));
      });
    }
    timeout = setTimeout(function() {
      $(".left").trigger("click");
    }, 10000);
    return false;
  });
});
```

I think JavaScript like this is JavaScript we've all written before. I know I have. Take a moment to study it and see if you can spot the problems with it. There's some much larger problems that we won't look at right now, but you should be able to spot a lot of "quick wins" that we can take care of right here and now. I highly recommend noting down on paper a list of all the problems you spot and comparing them to the one I came up with below, to see what you might miss and to see if you identify things I didn't.

I've split my list of problems into two parts. Firstly, the big problems:

- __Duplication__. the same block of code is used multiple times to animate the margin. Additionally, the event handlers for the click on `.left` and `.right` are almost identical too, along with numerous others.
- __Bad Selectors__. There's very little in the way of contextual selectors. What I mean by this is the selectors are too general, `$("ul")` for example.
- __Magic Values__. A new developer reading this would have no idea why the number `300` crops up so regularly. Nor would it be immediately obvious why this was sometimes negative 300.
- __Reusing selectors__. By my count there are __15__ invocations of `$(thing)`, often with the same thing passed in as on a line previous.
- __document ready abuse__. All the code is within one `$(function() {})` block.

Remember, `$(function() {})` is shorthand for `$(document).ready(function() {})`. Whenever you pass a function into `$()`, jQuery will presume you want it to run only when the document is ready.

And some things we can clean up immediately:

- Use of `return false`. Generally passing the event into the handler function and calling `e.preventDefault()` is preferred (I'll discuss why in more detail shortly).
- Using `click()` instead of the newer `on()` API.
- Referencing the number `10000` more than once. What if the client decides this number should be `5000`? We'd have to change it in three separate places.
- We can easily cache some selectors into variables, such as `$(".controls span")`.
- We can look at abstracting some of the duplication into functions. For example, lines 23, 30, 46 and 53 are identical.

## return false; the anti-pattern

Currently both the event handlers end with `return false`:

```javascript
$(".left").click(function() {
  // things happen here
  return false;
});
$(".right").click(function() {
  // things happen here
  return false;
});
```

This topic was first talked about back in 2010 in Doug Neiner's article ["Stop (mis)using Return False](http://fuelyourcoding.com/jquery-events-stop-misusing-return-false/) and is still very much relevant today.

jQuery event handlers take one argument, the _event object_. This object contains information about the event that triggered the event handler to fire. This object not only contains properties, such as the co-ordinates of the mouse pointer when the event took place, but also methods, including `preventDefault()` and `stopPropagation()`.

_Normally_ when a developer writes `return false`, what they actually want is to pass the event object in and call `event.preventDefault()`, like so:

```
$(".right").click(function(event) {
  // things happen here
  event.preventDefault();
});
```

As I'm sure you're aware, `preventDefault()` prevents the default action being taken. `return false` has the same effect, but it does something else too.

Let's just head out on a quick tangent to fully discuss propagation. Take a look at the code sample below:

```javascript
$(function() {
  $("div").on("click", function() {
    console.log("div got clicked");
  });
  
  $("div p").on("click", function(e) {
    console.log("p got clicked");
    e.stopPropagation();
  });
});
```

If you were to load that up in a browser and click on the `p` element within the `div` element, what would you see in the console? You would only see the second log statement, "p got clicked". `event.stopPropagation()` _stops the event from bubbling up the DOM tree_. There are occasions when this is useful but the majority of the time, you don't want this. What you might not realise though, is that __return false; has the same effect__. `return false` has the same effect as calling `preventDefault()` and `stopPropagation()`. This can lead to nasty side effects or bugs later which can be incredibly difficult and frustrating to deal with - trust me, I've been there.

So although it might take longer, it's much better to be a bit more verbose here. If you only want the default action to be prevented, call `preventDefault()`. If you want propagation to be prevented, call `stopPropagation()`. If you want them both, __don't type__ `return false;`. Be explicit and type them both out:

```javascript
event.stopPropagation();
event.preventDefault();
```

The question on where it makes sense to place calls to `preventDefault()` and `stopPropagation()` is largely down to you and your preference, but I like to put them at the top as the very first thing that happens in the method. That way it's easily spotted if you or another developer is reading through the code to see what it does.

So for our first quick win, we can swap out `return false` with calls to `event.preventDefault()`. I've also put `event.preventDefault()` at the top, above the rest of the event handler code (which I've left out here just to save room).

```javascript
$(".left").click(function(event) {
  event.preventDefault();
  // things happen here
});
$(".right").click(function(event) {
  event.preventDefault();
  // things happen here
});
```

## on() and off()

In jQuery 1.7 there was a new API introduced for binding and unbinding event handlers in the form of `on()` and `off()` to supersede the old API which was (and still is) a myriad of methods like `click()`, `hover()`, `mouseout()` along with `live()`, `bind()` and so on. This point may be a bit contentious, but I think that `on()` and `off()` are absolutely vast improvements and the fact that the entire event binding API was able to be reduced to two methods is brilliant. Of course, the old methods are not going anywhere (imagine how much code would break!) but as a rule I now will never use `click()` or similar, and will always use `on("click", function() {})`. This isn't going to bring you huge speed improvements or even gain any readability, but personally I do think it reads slightly nicer.

This one's easy. Just swap out the calls to `click` with `on`:

```javascript
$(".left").on("click", function(event) {
  event.preventDefault();
  // things happen here
});
$(".right").on("click", function(event) {
  event.preventDefault();
  // things happen here
});
```

## Repeated Numbers

Our code has some numbers that crop up time and time again. The first is `300`, which I'd refer to as a "Magic Number" and we'll tackle separately. The second is `10000`. This isn't so much a magic number in my opinion as it's not connected with the page as much. `300` refers to the width of an image, but it's not immediately apparent looking at the code that that is the case. We should treat it differently, and we will. `10000` has no connections, it's just simply the time we decided should be between each automatic progression of our carousel.

If I were in another language that has _constants_, I'd define this value as a constant at the top of the file. For example, if this was the language Ruby I could simply do:

```ruby
CAROUSEL_TRANSITION_TIME = 10000
```

That constant would then be set to 10,000 and nothing could possibly change it later on.

Although JavaScript doesn't have constants, a convention has formed that any variable in capital letters should be treated as such. So I'd actually type exactly what I typed above in the Ruby example, and place it towards the top of the JavaScript file:

```javascript
$(function() {
  var CAROUSEL_TRANSITION_TIME = 10000;

  if(location.hash && location.hash.indexOf("image") > -1) {
    // more code
```

And then I'd replace all occurrences of `10000` in the code with `CAROUSEL_TRANSITION_TIME`:

```javascript
var timeout = setTimeout(function() {
  $(".left").trigger("click");
}, CAROUSEL_TRANSITION_TIME);
```

And similarly in the other two places it occurs.

By doing this we've definitely made this code more maintainable. Say the client turns up and wants the value changed. Now we've just one value to change, instead of three. Try to get into the habit of defining things as constants early. You can always remove the constant if you end up using it once, but it's a good practice to get into if you find yourself referring to the same value over and over again.

I> Remember that constants should never be altered - in languages with actual support for constants, you are unable to edit them, you should treat your makeshift JavaScript constants equally.

## Caching selectors

This is something that everybody _should_ do but people don't always do it (I know I'm guilty). jQuery makes it so easy to quickly query the DOM for something that it's easy to just keep doing it and pay no attention to if you've done that previously or not. The common argument for this is largely performance. Whilst there is an obvious performance increase if you can avoid doing something multiple times, I would argue that today the main reason behind this should be the maintainability of your code. In the previous section we just swapped out occurrences of `10000` with a constant which took us from 3 changes down to 1 if that number should change.

Take a look at the carousel code and selectors that come up time and time again. There's not too many unique selectors but they all occur multiple times:

- `ul` (5 times)
- `.controls span` (5 times)
- `.left` (4 times)
- `.right` (once)

The fix for this is simple, and I'm sure you already know what's coming up. __Cache those selectors!__.

```javascript
var ul = $("ul");
var controlText = $(".controls span");
var leftLink = $(".left");
var rightLink = $(".right");
```

Now go through and replace all occurrences of each selector with the relevant variable. What we've achieved here is a much easier job, should any of these selectors change. If you take anything away from this section, make it be this:

__Anything that could change should only be referenced _once_ in your code__.

Make changes and alterations as frictionless as possible and everyone's happy.

## functions

We're going to look more in depth at functions in a later chapter, where we'll discuss their usage and some technical details in depth. This section can serve as a precursor to that.

A lot of people I talk to seem wary of using functions, like they come with some huge cost that people can't afford. In other communities like the Ruby one (which I'll reference purely because it's the one I'm most familiar with) it's very common to see posts heavily advocating using methods in Ruby. Ben Orenstein talks heavily about how he's incredibly aggressive at abstracting code into new methods and having methods of extremely short length. I agree with Ben's approach entirely we can certainly take some of what he says and apply it to our code.

As I said, we'll go much more into this later, but for now let's look at one quick example. This very line crops up four times:

```javascript
controlText.text("Current: " + (currentImage + 1));
```

By abstracting this line into its own function we can gain a large amount:

1. _Maintainability_. This code contains something that very much could change - the text that we put into the page to show the user what number they are on. Right now, that change would have to be made in four places.
2. _Readability_. If you extract code into a function and name that function well, it's then less code for a developer to have to read to understand the functionality. If, instead of the line above, we just had a call to `updateControlText()`, I can understand what that means _instantly_, and move on. I can understand what that means a lot quicker than I can understand what `controlText.text("Current: " + (currentImage + 1));` means.
3. Plus, it's a first step towards properly structuring our code, something we'll also look into in more detail later.

Let's make the change. At the top of the code, just below all your selector variables, add the function:

```javascript
var updateControlText = function() {
  controlText.text("Current: " + (currentImage + 1));
};
```

And then we can update the code to make use of it:

```javascript
ul.animate({
  "margin-left": number * -300
}, function() {
  currentImage = number;
  updateControlText();
});
```

(And in the other three locations too).

## Summary

With that change we've made __five__ really quick and simple changes that have already improved our code hugely, with very little time spent making them. As you get used to spotting these problems and fixing them, you'll find it becomes almost second nature to make them all the time, without thinking.

```javascript
$(function() {
  var CAROUSEL_TRANSITION_TIME = 10000;
  var ul = $("ul");
  var controlText = $(".controls span");
  var leftLink = $(".left");
  var rightLink = $(".right");
  
  var updateControlText = function() {
    controlText.text("Current: " + (currentImage + 1));
  };
  
  if(location.hash && location.hash.indexOf("image") > -1) {
    var number = parseInt(location.hash.charAt(location.hash.length -1));
    ul.animate({
      "margin-left": number * -300
    }, function() {
      currentImage = number;
      updateControlText();
    });
  }
  var timeout = setTimeout(function() {
    leftLink.trigger("click");
  }, CAROUSEL_TRANSITION_TIME);
  
  var currentImage = 0;
  leftLink.on("click", function(event) {
    event.preventDefault();
    clearTimeout(timeout);
    if(currentImage == $("li").length - 1) {
      ul.animate({
        "margin-left": 0
      }, function() {
        currentImage = 0;
        updateControlText();
      });
    } else {
      ul.animate({
        "margin-left": "-=300px"
      }, function() {
        currentImage+=1;
        updateControlText();
      });
    }
    timeout = setTimeout(function() {
      leftLink.trigger("click");
    }, CAROUSEL_TRANSITION_TIME);
  });
  
  rightLink.on("click", function(event) {
    event.preventDefault();
    clearTimeout(timeout);
    if(currentImage == 0) {
      ul.animate({
        "margin-left": ($("li").length - 1) * -300
      }, function() {
        currentImage = $("li").length - 1;
        updateControlText();
      });
    } else {
      ul.animate({
        "margin-left": "+=300px"
      }, function() {
        currentImage-=1;
        updateControlText();
      });
    }
    timeout = setTimeout(function() {
      leftLink.trigger("click");
    }, CAROUSEL_TRANSITION_TIME);
  });
});
```

In the next chapter we will look more in depth at a smaller block of code I wrote recently that's absolutely terrible, and see if we can't improve it.

