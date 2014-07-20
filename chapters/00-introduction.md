# Introduction

Welcome to The Refactoring Tales, a book that documents some of the refactorings and changes I've made in recent (and mostly real-life) projects. This book isn't going to teach you about language constructs, conditionals, functions, or so on, but hopefully offer insight into how to take steps to make your code more readable and more importantly, maintainable.

Think of how much time you spend maintaining code, rather than being able to write code from scratch. Day to day, I'm not typically creating new projects, but I am maintaining, editing or refactoring existing projects. This book is just like that. Each chapter will start by looking at some existing code, and over the course of a few pages we will examine, disect and then refactor the code into an improved alternative. Of course, the idea of code being "better" is largely subjective, but even if you don't quite agree with every step I take, you should be able to see the overall benefits.

The GitHub repository for this book is here: [https://github.com/jackfranklin/the-refactoring-tales](https://github.com/jackfranklin/the-refactoring-tales), both the raw book files and the code samples are all there for you to take. If you spot any issues as you read this book, a new issue (or even better, a pull request!) is greatly appreciated.

## Refactoring

Before we continue I think it's important to define just what exactly I mean when I say "refactoring". Refactoring has lots of definitions, but I think my favourite and the one I stick to is that of Martin Fowler, in his [book on refactoring](http://martinfowler.com/books/refactoring.html):

> Refactoring is a controlled technique for improving the design of an existing code base. Its essence is applying a series of small behavior-preserving transformations, each of which "too small to be worth doing". 

We apply small changes to the code, and do so several times, until we're left with a section of code whose design is greatly improved. Notice how they are _behaviour-preserving_ transformations: a refactor should never change behaviour, merely improve the code. The idea of "better" code may be subjective, but to me when I think of good qualities for code to have, I think of it being:

- self documenting: methods and variables are well named and follow a consistent naming pattern
- DRY: there is no duplication or knowledge sharing; every piece of information that could change is declared only once
- clear in its intention; it should read somewhat like a story, and at a quick skim the overall function of that block of code should be apparent

In his book [Professional JavaScript for Web Developers](http://www.wrox.com/WileyCDA/WroxTitle/productCd-0764579088.html), Nicholas Zakas has a brilliant definition of maintainability which cites the following characteristics: Understandable, intuitive, adaptable, extendable and debuggable. It's these traits that I hope this book will help you adhere to and aim for.

## Tests

When refactoring, you need to have confidence in the fact that you've not broken anything. Similarly, if you do break something, you need to know immediately. This is where the benefit of having tests plays a key role. The ability to run a set of tests and get immediate feedback is fantastic, and that's precisely what tests give you. It's very easy these days to get started with tests, whether you're writing Ruby, or JavaScript on the server with NodeJS, or in the browser, there are a myriad of tools available to you. This isn't a book on testing, and I could write in huge depth on the subject, so for each example in this book, you should assume that I have tested it as I've gone (in actual fact for every example there is, I did have tests everytime). If you want to refactor but don't have tests, write tests. Do not ever attempt to refactor without writing any tests. Ever.

You should also make sure you can run your tests easily. I have mine hooked up through my editor, Vim, so I can hit a 3 key shortcut and have my tests run. Configure it however you want, and make sure it's easy to do.

## Thanks

There are so many people who have thanked me along the way that it would be wrong to not include some form of list of names in this book. Thanks in particular go to Addy Osmani, Drew Neil, Guy Routledge, Katja Durrani, Adam Yeats, Stu Robson and Todd Motto along with many more who have shaped this book since the idea formed.

