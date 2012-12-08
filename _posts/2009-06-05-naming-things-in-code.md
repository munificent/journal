---
layout: post
title: "Naming Things in Code"
#categories: code, language
---
When I'm designing software, I spend a lot of time thinking about names. For
me, thinking about names is inseparable from the process of design. To name
something is to define it.

> In the beginning was the Word, and the Word was with God, and the Word was
God.

<p class="cite">The Gospel According to John</p>

One of the ways I know a design has really clicked is when the names feel
right. It may take some time for this to happen (I rename things a *lot* when
I'm first putting them down in code), but that's OK. Good design doesn't
happen fast.

Of course, good names alone don't make a good design, but it's been my
experience that crappy names do *prevent* one. With that in mind, here's the
guidelines I try to follow when naming things. The examples here are in C++,
but work more or less for any language.

## Types (Classes, Interfaces, Structs)

### The name should be a noun phrase.

{% highlight text %}
Bad:  Happy
Good: Happiness
{% endhighlight %}

### Do not use namespace-like prefixes.

That's what namespaces are for.

{% highlight text %}
Bad:  SystemOnlineMessage
Good: System::Online::Message
{% endhighlight %}

### Use just enough adjectives to be clear.

{% highlight text %}
Bad:  IAbstractFactoryPatternBase
Good: IFactory
{% endhighlight %}

### Do not use "Manager" or "Helper" or other null words in a type name.

If you need to add "Manager" of "Helper" to a type name, the type is either
poorly named or poorly designed. Likely the latter. Types should manage and
help themselves.

{% highlight text %}
Bad:  ConnectionManager
      XmlHelper
Good: Connection
      XmlDocument, XmlNode, etc.
{% endhighlight %}

### If a class doesn't represent something easily comprehensible, consider a concrete metaphor.

{% highlight text %}
Bad:  IncomingMessageQueue
      CharacterArray
      SpatialOrganizer
Good: Mailbox
      String
      Map
{% endhighlight %}

### If you use a metaphor, use it consistently.

{% highlight text %}
Bad:  Mailbox, DestinationID
Good: Mailbox, Address
{% endhighlight %}

## Functions (Methods, Procedures)

### Be terse.

{% highlight text %}
Bad:  list.GetNumberOfItems();
Good: list.Count();
{% endhighlight %}

### Don't be too terse.

{% highlight text %}
Bad:  list.Verify();
Good: list.ContainsNull();
{% endhighlight %}

### Avd abbrvtn.

{% highlight text %}
Bad:  list.Srt();
Good: list.Sort();
{% endhighlight %}

### Name functions that do things using verbs.

{% highlight text %}
Bad:  obj.RefCount();
Good: list.Clear();
      list.Sort();
      obj.AddReference();
{% endhighlight %}

### Name functions that return a boolean (i.e. predicates) like questions.

{% highlight text %}
Bad:  list.Empty();
Good: list.IsEmpty();
      list.Contains(item);
{% endhighlight %}

### Name functions that just return a property and don't change state using nouns.

{% highlight text %}
Bad:  list.GetCount();
Good: list.Count();
{% endhighlight %}

(In C#, you'd actually use properties for this.)

### Don't make the name redundant with an argument.

{% highlight text %}
Bad:  list.AddItem(item);
      handler.ReceiveMessage(msg);
Good: list.Add(item);
      handler.Receive(msg);
{% endhighlight %}

### Don't make the name redundant with the receiver.

{% highlight text %}
Bad:  list.AddToList(item);
Good: list.Add(item);
{% endhighlight %}

### Only describe the return in the name if there are identical functions that return different types.

{% highlight text %}
Bad:  list.GetCountInt();
Good: list.GetCount();
      message.GetIntValue();
      mmessage.GetFloatValue();
{% endhighlight %}

### Don't use "And" or "Or" in a function name.

If you're using a conjunction in the name, the function is likely doing too
much. Break it into smaller pieces and name accordingly.

If you want to ensure this is an atomic operation, consider creating a name
for that entire operation, or possibly a class that encapsulates it.

{% highlight text %}
Bad:  mail.VerifyAddressAndSendStatus();
Good: mail.VerifyAddress();
      mail.SendStatus();
{% endhighlight %}

## Does it Matter?

Yes, I firmly believe it does. A module with well-named parts quickly teaches
you what it does. By reading only a fraction of the code, the you'll quickly
build a complete mental model of the whole system. If it calls something a
"Mailbox" you'll expect to see "Mail", and "Addresses" without having to read
the code for them.

Well-named code is easier to talk about with other programmers, helping
knowledge of the code to spread. No one wants to try to say
"ISrvMgrInstanceDescriptorFactory" forty times in a meeting.

Over on the other side, poor names create an opaque wall of code, forcing you
to painstakingly run the program in the your head, observe its behavior and
then create your own private nomenclature. "Oh, `DoCheck()` looks like it's
iterating through the connections to see if they're all live. I'll call that
`AreConnectionsLive()`." Not only is this slow, it's non-transferrable.

From the code I've seen, there's a strong correspondence between a cohesive
set of names in a module, and a cohesive module. When I have trouble naming
something, there's a good chance that what I'm trying to name is poorly
*designed*. Maybe it's trying to do too many things at once, or is missing a
critical piece to make it complete.

It's hard to tell if I'm designing well, but one of the surest guides I've
found that I'm *not* doing it well is when the names don't come easy. When I
design now, I try to pay attention to that. Once I'm happy with the names, I'm
usually happy with the design.
