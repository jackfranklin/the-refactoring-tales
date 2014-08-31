# Test Driven Development

This chapter is slightly different from the rest. This isn't a tale of some bad code turned good, but rather how I used test driven development (TTD) to create a function and my thoughts on how this effected the resulting code.

TTD often is thought of as foolish - writing a test that won't pass because you've not written code seems unintuitive. The key thing that it does allow you to do is interact with the new code you're about to write, and get a feel for what the API should look like. That's a great benefit, and often I've rewritten tests many times as I figure out what the public API of the new object I'm building should look like. Another benefit though, is it lets you take small steps to successfully implementing a function. You can write your tests one at a time, and get them green one by one. Write one, make it green, and then write the next. At any point if you break a previous test, you'll know right away. It's that confidence that you've not inadvertently broken something that I enjoy most about a good test suite.

## The Service

I'm working on an application where users have these objects, called "clusters", that are groups of posts from another site. They can share these clusters with other users, who can subscribe to them. However, users can choose to keep their clusters private, and so only they can see them. I needed to build some logic for deciding if a user is allowed to subscribe to a cluster. There are various rules that govern this:

- If a user is the owner of the cluster, they cannot subscribe, because they are implictly subscribed to it by owning it.
- If the user is an admin of the cluster, they cannot subscribe, for the same reason as above.
- If the cluster is private, no user can subscribe to it.
- If a user is already subscribed to the cluster, they cannot subscribe to it again.

Else, if none of the four above conditions match, the user is allowed to subscribe.

## Test Driven

This is the perfect example of a function that is very easy to test. Given specific input, it will either return `true` (the user can subscribe), or `false` (the user cannot subscribe). There are a few conditions we need to make sure we adhere to, so a set of unit tests is the perfect way to do this.

Let's write the first test. Here I'm using the [Jasmine testing library](http://jasmine.github.io/2.0/introduction.html), but if you prefer another, feel free to use it instead. Jasmine is just my framework of choice for testing JS on the client. The actual implementation of this code was done within Angular, so in the tests there's a fair amount of setup for that, which I'm ignoring here. The best way to test drive this is to write one spec, make it pass _in the easiest way possible_, and then write the next one.

Here's my first test:

```js
it('returns true if the user is not admin or owner and the cluster is public', function() {
  var res = UserCanSubscribeService.canSubscribe({
    id: 'abcd'
  }, {
    public: true,
    admins: [],
    subscribers: [],
    owner: 'cdef'
  });
  expect(res).toEqual(true);
});
```

Here I'm stating that the `canSubscribe` method takes two arguments: the first is the user object, which for testing purposes can just contain an ID. The second object is then the cluster that they may or may not be allowed to subscribe to. In this instance, the user is not the cluster owner, is not an admin, has not subscribed already and the cluster is public, so they are able to subscribe.

The simplest implementation to make this work?

```js
UserCanSubscribeService = {};
UserCanSubscribeService.canSubscribe = function() {
  return true;
}
```

The test passes, but obviously that implementation needs a bit more work doing. However the point here, even if this might seem a little pointless, is to go one test at a time and make small steps. What this does is stops you over complicating your initial approach and potentially abstracting in the wrong place. A bad abstraction is worse than no abstraction, and by waiting until you have more code and context, you are more likely to pick the right abstraction.


## Conclusion

The above code has been altered slightly for easier reading, but I did actually write this service in a real application. If you're interested, you can [find it on GitHub](https://github.com/clusterapp/client/tree/master/app/shared/user-can-subscribe-service).
