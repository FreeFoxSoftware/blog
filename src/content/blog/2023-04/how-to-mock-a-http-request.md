---
author: Scott Walker
pubDatetime: 2023-04-30T21:30:00Z
title: How to Mock a HTTP Request When Unit Testing with C# and XUnit
postSlug: how-to-mock-http-requests
featured: false
draft: false
tags:
  - Mocking
  - Unit Testing
  - HTTP
  - Csharp
  - xunit
ogImage: ""
description: Unit Testing is an important aspect of developing software and HTTP requests will undoubtably come into this. We don't want to actually make those requests so here I'll explain how we can mock out any HTTP requests!
---

Unit Testing has for many years been an accepted way of automating your software tests at a detail level. As a part of these tests, we have to exclude any services outside of our scope especially services outside of our control, you never want a unit test to fail because of a HTTP request for instance. So, let's go through and show a method of mocking our HTTP requests.

> Small caveat at this point. This will only work using the recommended way of passing a HttpClient into the class via DI.

## Why We're Not Using a Mocking Library

The immediate question that I'd expect is 'why not use something like `Moq`'. The answer is because we're not actually going to be mocking the HttpClient directly, we'll be mocking out the HttpMessageHandler which is what actually makes the request. The problem with this class is that it is both `protected` and `abstract` which Moq doesn't handle as nicely as it handles the likes of `public` function and `interfaces`. It can be done of course but I always find that it adds so much clutter to the test that it makes it difficult to read and difficult to work with.

## Replacing the HTTP requests

Imagine the following scenario:

```csharp
public class Availability
{
    private readonly HttpClient _client;

    public Availability(HttpClient client)
    {
        _client = client;
    }

    public async Task<bool> IsGoogleAvailable()
    {
        var response = await _client.GetAsync("https://google.com");

        return response.IsSuccessStatusCode;
    }
}
```

Now when we're testing this, there are two tests that we can faesibly write. A test that asserts that we have true returned when Google is available and one that returns false when it's not available. We obviously don't want to call Google when doing this so let's have a look at how we can fake this!

We're going to make a new class which can replace our HTTP calls.

```csharp

public class TestHttpMessageHandler : HttpMessageHandler
{
    private readonly Queue<HttpResponseMessage> _responses = new();

    public void SetResponse(HttpResponseMessage response)
    {
        _responses.Enqueue(response);
    }

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        return Task.FromResult(_responses.Dequeue());
    }
}

```

You can see that we're inheriting the `HttpMessageHandler` class and also overriding the `SendAsync` function. So every time a HTTP request is made it will go through our SendAsync function. The other thing you'll notice is that we're dequeueing something every time this is called. This is the response we're going to give back to the calling code. So for our 'success' test we'll have it return an 'OK' response and for our 'Google unavailable' test we can have it return any of the 400's. 

```csharp
    [Fact]
    public async Task WhenGoogleIsAvailable_ShouldReturnTrue()
    {
        var testHandler = new TestHttpMessageHandler();
        var httpClient = new HttpClient(testHandler);
        var sut = new Availability(httpClient);
        
        testHandler.SetResponse(new HttpResponseMessage(HttpStatusCode.OK)); // Set the response that the client should return
        var response = await sut.IsGoogleAvailable();
        Assert.True(response);
    }
    
    [Fact]
    public async Task WhenGoogleIsNotAvailable_ShouldReturnFalse()
    {
        var testHandler = new TestHttpMessageHandler();
        var httpClient = new HttpClient(testHandler);
        var sut = new Availability(httpClient);
        
        testHandler.SetResponse(new HttpResponseMessage(HttpStatusCode.BadRequest));
        var response = await sut.IsGoogleAvailable();
        Assert.False(response);
    }
```

Most of this test is self explanatory but all we're interested in is the line where we're setting the response. We can pass in any HttpResponseMessage here so we can pass back JSON, XML or, as in our case, a simple 'OK' or 'BadRequest'.

## What About Callbacks?

Something that we're missing from all of this that the Moq framework provides is `callbacks`. Essentially, we want to be able to see what data was called when the HTTP request was made. Thanks to our little helper class, we can do this simply.

```csharp
    private readonly Stack<HttpRequestMessage> _completedRequests = new();
    
    public HttpRequestMessage PopRequest()
    {
        return _completedRequests.Pop();
    }

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        _completedRequests.Push(request); // This has been added
        return Task.FromResult(_responses.Dequeue());
    }

```

Here we create a `stack` of all the requests that have been completed. So if we wanted to get information on the last request made then we can just use the `PopRequest` function which will give us our last request back. The choice to use a `stack` is a personal one. I find that I more often than not want the last request made rather than the first one but if your use case is different then you could easily switch this to another queue or any data structure of your choice (as long as it guarantees order).

When complete, our code looks like this

```csharp
public class TestHttpMessageHandler : HttpMessageHandler
{
    private readonly Queue<HttpResponseMessage> _responses = new();
    private readonly Stack<HttpRequestMessage> _completedRequests = new();

    public void SetResponse(HttpResponseMessage response)
    {
        _responses.Enqueue(response);
    }

    public HttpRequestMessage PopRequest()
    {
        return _completedRequests.Pop();
    }

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        _completedRequests.Push(request);
        return Task.FromResult(_responses.Dequeue());
    }
}

```


## Conclusion

That's the end of this one! Here we went through a simple way of mocking HTTP requests by creating our own helper class. There are of course many ways to be able to do this but I hope that you found this one somewhat useful. If you're interested in the source code for this, you can find the repo on my employers Github page [here](https://github.com/ShipitSmarter/ShipitSmarter.TestHelpers/blob/main/src/ShipitSmarter.TestHelpers/TestHttpMessageHandler.cs) along with some other useful helper methods. It's also available as a Nuget package if you need it!

Thanks for reading.✌🏻
