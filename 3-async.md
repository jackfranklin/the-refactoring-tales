# Tale 3: Async Abominations
https://github.com/clusterapp/api/commit/a4b2ffee942114dcbd210d93666f64fd563016d7


BEFORE: https://github.com/clusterapp/api/blob/3cdbf512aa1d1f5946b87c978505910b106e2503/routes/param_validator.js

AFTER: https://github.com/clusterapp/api/blob/a4b2ffee942114dcbd210d93666f64fd563016d7/routes/param_validator.js

The code for this example comes directly from a project I was working on recently. I was building a NodeJS powered API, and as part of that, needed a way of validating parameters that were passed as query strings in the API request. Every single request needs to be passed a `token` parameter, which is matched to the token of a user in the database, and some requests take a `userId` parameter, along with a token. In the case that both the token and userId are passed in, we validate that the token is the token for that specific user. In the case wehre we just take in a token, we validate that the token is valid, and exists in our database.

The API has many routes, so I wanted to abstract this into a function, which I called `validateParamsExist`. It is used like so:

```js
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

```js
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


```js
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

```js
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

```js
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

Doing this also means we can get rid of the `if(!req.query)` conditional that wrapped most of the body of the `validateParamsExist` method. I find exiting early is preferable to wrapping functions in large conditionals. These are what we call __guard clauses__.
