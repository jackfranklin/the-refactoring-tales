# Tale 3: Async Abominations

The code for this example comes directly from a project I was working on recently. I was building a NodeJS powered API, and as part of that, needed a way of validating parameters that were passed as query strings in the API request. Every single request needs to be passed a `token` parameter, which is matched to the token of a user in the database, and some requests take a `userId` parameter, along with a token. In the case that both the token and userId are passed in, we validate that the token is the token for that specific user. In the case wehre we just take in a token, we validate that the token is valid, and exists in our database.

The API has many routes, so I wanted to abstract this into a function, which I called `validateParamsExist`. It is used like so:

```javascript
validateParamsExist(['userId', 'token', 'foo'], req, res, function(requestIsValid) {
  if(requestIsValid) {
    // all parameters were passed
  } else {
    // something went wrong
  }
});
```

The function takes four arguments:
- an array of parameters to ensure exist
- the ExpressJS request object (don't worry if you don't know what it is, all you need to know is that it stores all the information about the request)
- the ExpressJS response object (this is what we use to return data from the API)
- a callback function, which is called once the validation is complete with a single argument, which is `true` if the validations passed, and `false` if it did not.

It's also important to note that the ExpressJS request object (in the code, I refer to it as `req`), stores the parameters that we got with the URL in an object, which is stored in `req.query`. So if I made a request that looked like this: `http://somesite.com/foo?name=jack&id=123`, `req.query` would look like so:

```javascript
req.query = {
  name: 'jack',
  id: '123'
};
```

The challenge here and why this refactor offers a different challenge to the others is because it's asynchronous. It performs tasks asynchronously and hence it's a bit more of an effort to pull pieces out. The basic idea for the implementation of this function is as follows:

1. Loop over every parameter the user is expecting, and make sure it exists
2. If the parameter is `token`, do some extra validation (as explained above). The exact extra validation to be done depends on if we also have a `userId` parameter or not.

## The code

Rather than show you the starting code, which is badly written and tough to understand, I'm going to show you the finished code first. This is what my refactoring lead me to:


```javascript
var matchTokenToUser = function(token, userId, errors, done) {
  // method for making sure a token matches a user
}

var ensureTokenExists = function(token, errors, done) {
  // method for ensuring a token exists
};

var noParamsPassed = function(req, res) {
  if(req.query) {
    return false;
  } else {
    res.json({ errors: ['no parameters supplied'] });
    return true;
  }
};

var checkTokenAndIds = function(req, errors, cb) {
  var token = req.query.token;
  var userId = req.query.userId;
  if(token) {
    if(userId) {
      matchTokenToUser(token, userId, errors, cb);
    } else {
      ensureTokenExists(token, errors, cb);
    }
  } else {
    cb();
  }
};

var validateParamsExist = function(params, req, res, cb) {
  if(noParamsPassed(req, res)) return cb(false);
  
  var errors = [];
  params.forEach(function(p) {
    if(!req.query[p]) errors.push('parameter ' + p + ' is required');
  });
  
  checkTokenAndIds(req, errors, function() {
    if(errors.length > 0) {
      res.json({ errors: errors });
      return cb(false);
    } else {
      return cb(true);
    }
  });
};
```

Have a read through the code, starting with the `validateParamsExist` method, and see if it makes sense. I have left some implementation details of functions out, because it plays no part in the refactoring (the method we'll start with shortly also has `ensureTokenExists` and `matchTokenToUser`, too).

Stepping through the `validateParamsExist` method, here's what it does:

1. If no parameters at all were passed, call the callback and pass in `false`, because the validation failed.
2. Go through each parameter we are expecting, and make sure that it actually exists. If it doesn't, store an error in the `errors` array.
3. Check to see if the token and id parameters were passed, and ensure that they are as expected.
4. Once the checking of tokens and id are complete, check to see if the `errors` array has any items. If it does, use `res.json` to return those errors from the API, and call the callback with `false`, because the validation failed.
5. Else, if we have no errors, call the callback with `true`, because the validation must have passed.

## Back to the beginning

I showed you the finished version first because it's readable and easy to digest what is going on, everything the first implementation isn't. What we'll do now is look at the pre-refactoring code and then step through the refactorings I made to get to the above code. Brace yourself, because here is the previous version:

```javascript
var matchTokenToUser = function(token, userId, errors, done) {
  // implementation irrelevant
}

var ensureTokenExists = function(token, errors, done) {
  // implementation irrelevant
};

var validateParamsExist = function(params, req, res, cb) {
  if(!req.query) {
    res.json({ errors: ['no parameters supplied'] });
    return cb(false);
  } else {
    var errors = [];
    async.each(params, function(p, callback) {
      if(!req.query[p]) {
        errors.push('parameter ' + p + ' is required');
        callback();
      } else {
        if(p === 'token' && req.query.token) {
          if(params.indexOf('userId') > -1 && req.query.userId) {
            matchTokenToUser(req.query.token, req.query.userId, errors, callback);
          } else {
            ensureTokenExists(req.query.token, errors, callback);
          }
        } else {
          callback();
        }
      }
    }, function(err) {
      if(errors.length > 0) {
        res.json({ errors: errors });
        return cb(false);
      } else {
        return cb(true);
      }
    });
  };
}
```

Take a moment to read through that and see what's going on. The good news is it can't get any worse than this - things are only going to get better from here!

## Abstracting functions

Before I even begin to look at the main block of code, that starts with the call to `async.each`, I like to immediately abstract out small blocks into functions. This is the kind of change that I might undo at a later point, but I find it really helps as a starting point to just split one large method up into a bunch of smaller functions if possible. The first bit we can do that for is the first part of our function, the `if(!req.query)...` part:

```javascript
var noParamsPassed = function(req, res) {
  if(req.query) {
    return false;
  } else {
    res.json({ errors: ['no parameters supplied'] });
    return true;
  }
};

var validateParamsExist = function(params, req, res, cb) {
  if(noParamsPassed(req, res)) return cb(false);
  var errors = [];
  async.each(params, function(p, callback) {
    if(!req.query[p]) {
      errors.push('parameter ' + p + ' is required');
      callback();
    } else {
      if(p === 'token' && req.query.token) {
        if(params.indexOf('userId') > -1 && req.query.userId) {
          matchTokenToUser(req.query.token, req.query.userId, errors, callback);
        } else {
          ensureTokenExists(req.query.token, errors, callback);
        }
      } else {
        callback();
      }
    }
  }, function(err) {
    if(errors.length > 0) {
      res.json({ errors: errors });
      return cb(false);
    } else {
      return cb(true);
    }
  });
}
```

Doing this also means we can get rid of the `if(!req.query)` conditional that wrapped most of the body of the `validateParamsExist` method. I find exiting early is preferable to wrapping functions in large conditionals. These are what we call __guard clauses__ - a conditional which checks something that is required for the function to be able to run. If it's not there, it's best to figure it out right away and ditch out early. Some argue that functions having multiple returns makes them unclear, but I'd much rather that then have large conditionals wrapping functions. Those are much more unclear, in my opinion.

The next abstraction is to pull out the code that checks for the existance of `token` and/or `userId` parameters.

```javascript
var checkTokenAndIds = function(p, req, errors, callback) {
  if(p === 'token' && req.query.token) {
    if(params.indexOf('userId') > -1 && req.query.userId) {
      matchTokenToUser(req.query.token, req.query.userId, errors, callback);
    } else {
      ensureTokenExists(req.query.token, errors, callback);
    }
  } else {
    callback();
  }
};

// left out noParamsPassed fn so this code takes up less room

var validateParamsExist = function(params, req, res, cb) {
  if(noParamsPassed(req, res)) return cb(false);
  var errors = [];
  async.each(params, function(p, callback) {
    if(!req.query[p]) {
      errors.push('parameter ' + p + ' is required');
      callback();
    } else {
      checkTokenAndIds(p, req, errors, callback);
    }
  }, function(err) {
    if(errors.length > 0) {
      res.json({ errors: errors });
      return cb(false);
    } else {
      return cb(true);
    }
  });
}
```

The `checkTokenAndIds` is far from a perfect function, and later we will refactor it. However, once we get to the stage where we've pulled code out into functions, we can now digest `validateParamsExist` much easier.

When I started to look at this code, the first thing I spotted was how all of this code is wrapped within an `async.each` call. This is part of the fantastic [async](https://github.com/caolan/async) library. `async.each` offers a way to loop over an array and perform some asynchronous code for each, and then run some other code once all items have been looped over. The usage of it above though is far from sensible:


1. The first part of the `async.each`, which checks for the existant of a parameter, is not asynchronous.
2. The second part, which checks the validity of any token or userId params, only needs to run once, not every time.

It turns out that the only part of this code which does need to run in a loop is the parameter existance check, and that's not asynchronous. We can run the code that checks for tokens and ids only once, so why is it in a loop?! (As an aside, when I wrote this code the first time I didn't spot this. Looking back, I'm not sure what I was thinking!).

Making the first step of changes leaves us with code that looks like this:

```javascript
var validateParamsExist = function(params, req, res, cb) {
  if(noParamsPassed(req, res)) return cb(false);
  var errors = [];
  params.forEach(function(p) {
    if(!req.query[p]) errors.push('parameter ' + p + ' is required');
  });

  // need to checkTokenAndIds next
  //...
}
```

The signature of the `checkTokenAndIds` function needs to change somewhat now. Previously we passed in the current parameter, but now we just need to give it all the parameters, our array of errors, and a function to call when it's finished its checks. Here's the final version of the `checkTokenAndIds` method I came up with:

```javascript
var checkTokenAndIds = function(req, errors, cb) {
  var token = req.query.token;
  var userId = req.query.userId;
  if(token) {
    if(userId) {
      matchTokenToUser(token, userId, errors, cb);
    } else {
      ensureTokenExists(token, errors, cb);
    }
  } else {
    cb();
  }
};
```

Don't worry about the implementation of `matchTokenToUser` or `ensureTokenExists` - they are both simple methods that just run some database queries, but they have no effect on this chapter. Notice how this method tells a story very effectively, and it's easy to go down it line by line and see what's happening, and follow the story. We can now go and add this method back into `validateParamsExist`:

```javascript
var validateParamsExist = function(params, req, res, cb) {
  if(noParamsPassed(req, res)) return cb(false);
  var errors = [];
  params.forEach(function(p) {
    if(!req.query[p]) errors.push('parameter ' + p + ' is required');
  });

  checkTokenAndIds(req, errors, function() {
    if(errors.length > 0) {
      res.json({ errors: errors });
      return cb(false);
    } else {
      return cb(true);
    }
  });
}
```

And we're done! This example was slightly different to previous examples - whilst the previous two chapters had code that was pefectly OK but had potential for some improvement, this code was just plain misleading, poorly constructed and badly written. Imagine if you had to make a change to the validation logic, and you had this block of code as your starting point. Do you think you could do it easily? I'm pretty sure I couldn't.

```javascript
var validateParamsExist = function(params, req, res, cb) {
  if(!req.query) {
    res.json({ errors: ['no parameters supplied'] });
    return cb(false);
  } else {
    var errors = [];
    async.each(params, function(p, callback) {
      if(!req.query[p]) {
        errors.push('parameter ' + p + ' is required');
        callback();
      } else {
        if(p === 'token' && req.query.token) {
          if(params.indexOf('userId') > -1 && req.query.userId) {
            matchTokenToUser(req.query.token, req.query.userId, errors, callback);
          } else {
            ensureTokenExists(req.query.token, errors, callback);
          }
        } else {
          callback();
        }
      }
    }, function(err) {
      if(errors.length > 0) {
        res.json({ errors: errors });
        return cb(false);
      } else {
        return cb(true);
      }
    });
  };
}
```

Compare that to the code we ended up with after sitting back, carefully going through the method to see exactly what it does and how it should work. The code is cleaner, its intention is obvious, there's less nesting and indentation (a very basic, but often useful metric) and it reads nicer.

Any developer who tells you that they have never looked back over some code they've previously written and cringed is a liar. You're never going to get it right first time, and the purpose of this book isn't to try to make you to produce great code first time, but to spot where improvements can be made. Andy Appleton, a developer I've had the pleasure with working with, put this best when we were talking about this kind of thing one day. He said:

> Defer concrete decisions as late as possible - you'll never again know less about the problem than you do right now and the correct abstraction will become clearer over time.

As time goes on and you become more settled within the context of what you're working on, refactorings, abstractions of classes and small tweaks should become easier to spot over time.
