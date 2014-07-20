# Tale 4: Parsing Problems

In this chapter we're not going to look in as much detail at implementation specifics as we did in the first, but more on the overall structure of bits of code across a large system. Whilst the structure of individual blocks of code is important, arguably more so is the relationship of these components across a software system, and it's this that I want to talk about in this chapter.

## Email Sending

As always, we need some code to work with, and this time we're looking at some code that has to send emails. It takes in a CSV, which contains details of users, including their email address, and uses that data to get a list of emails, which it then takes and sends an email to.

```js
var EmailSender = {
  init: function(csv) {
    this.csv = csv;
    return this;
  },
  parseEmailsFromCsv: function() {
    // implementation not important
    this.emails = [...]
  },
  sendEmail: function() {
    // sends email, implementation not important
    this.emails.forEach(...);
  }
};
```

On the surface of it, this object might seem pretty perfect to you. I've simplified it down slightly for the purposes of this book, but the details are mostly the same. It has a method to parse the emails out of the CSV, and then a method to take those emails and send an email to them.

## Single Responsibility Principle

However, this code violates the Single Responsibility Principle (or SRP, as I'll refer to it from now on). The Single Responsibility Principle states that one object should __do one thing__, and __do it well__. Our email sender right now has two responsibilities:

1. Parse the user emails out of a CSV.
2. Send an email to a list of email addresses

To me, that looks like two distinct responsibilities. Whilst this might not be an issue now, in the future of this large app you could imagine another part of the system wanting to send emails, or needing to parse data out of a CSV. Splitting this code up into two objects will benefit us now, but will probably benefit us more in the long run. This doesn't mean that tomorrow at work you should aggressively split up a single object into many smaller ones, but spotting instances where an object is doing too much is a good skill to master. Often these type of refactorings are more about saving pain later down the line than immediate reward, but that doesn't make them any less worthwhile. Long term, once you get used to the concept of SRP, you will find yourself keeping it in mind from the very moment you begin to build a new object.

## An improvement

Just like any other improvement, we're going to do it in small steps. Firstly, I can create a `Parser` object, that takes a CSV and can pull details out of it:

```js
var Parser = {
  init: function(csv) {
    this.csv = csv;
    return this;
  },
  parseEmails: function() {
    ... // not important
    return emails;
  }
};
```

Now we have a `Parser` class that definitely fits the SRP - it knows how to parse data out of a CSV, and that's the way it should be. We can now go ahead and update our `EmailSender` object:

```js
var EmailSender = {
  init: function(csv) {
    this.csv = csv;
    return this;
  },
  parseEmailsFromCsv: function() {
    // implementation not important
    this.emails = Parser.init(this,csv).parseEmails()
  },
  sendEmail: function() {
    // sends email, implementation not important
    this.emails.forEach(...);
  }
};
```

Notice how I haven't changed the methods available on `EmailSender`, but just the implementation so it uses the new `Parser` object.

## Coupling

We are far from done here, but before continuing I want to talk about the concept of __coupling__. In a large system, coupling is the amount two components rely on each other to perform their functions. [Wikipedia](http://en.wikipedia.org/wiki/Coupling_(computer_programming)) puts this nicely:

> In software engineering, coupling or dependency is the degree to which each program module relies on each one of the other modules.

The best way to judge this is to take your two components and ask yourself this question: if one of these components were to change, how much would the other have to change? If the answer is "lots", those components are tightly coupled. The overall aim is to have most of your components _decoupled_ from each other, so that if one changes, the other doesn't have to. Have you ever had to make a change to a system, and had to update code in multiple files at the same time? If so, that's a good indication that all those files and components are perhaps too tightly coupled to each other.

Some coupling is necessary, because without any coupling, no component would ever be able to talk to another, but the less components know about each other, the better.

Looking at our code and where we're up to, I'd argue that we have some coupling going on that isn't required.

```js
var Parser = {
  init: function(csv) {
    this.csv = csv;
    return this;
  },
  parseEmails: function() {
    ... // not important
    return emails;
  }
};

var EmailSender = {
  init: function(csv) {
    this.csv = csv;
    return this;
  },
  parseEmailsFromCsv: function() {
    // implementation not important
    this.emails = Parser.init(this,csv).parseEmails()
  },
  sendEmail: function() {
    // sends email, implementation not important
    this.emails.forEach(...);
  }
};
```

Here, `EmailSender` knows too much about how it gets emails. It knows that they come from the `Parser`, which uses a CSV as a data source. Why should the email sender know any of this? All we should give it is a set of emails, and it should do the rest. The next change we make is to decouple the components completely:

```js
var Parser = {
  init: function(csv) {
    this.csv = csv;
    return this;
  },
  parseEmails: function() {
    ... // not important
    return emails;
  }
};

var EmailSender = {
  init: function(emails) {
    this.emails = emails;
    return this;
  },
  sendEmail: function() {
    // sends email, implementation not important
    this.emails.forEach(...);
  }
};

var emails = Parser.init(csv).parseEmails();
EmailSender.init(emails).sendEmail();
```

Notice how now the `EmailSender` has no knowledge of the `Parser` even existing. This now means if our data source were to change from being CSV to being from a database for example, we wouldn't have to change any code. We could introduce a new object responsible for pulling our emails out of the database, and then still use `EmailSender` just like before.
