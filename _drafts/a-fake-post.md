---
layout: post
title: A Fake Post to Test Formatting
categories: code design blog test css
---

This is a fake post to check out all of the different kinds of formatting that need to be styled. This paragraph uses *emphasis* and also contains a bit of `inline code`. No paragraph would be complete without a [link](/) either.

<div class="update">
<p><em>Update 2011/09/9:</em> This is a fake update.</p>
</div>

Here is a code block with the maximum code width (70 characters):

```java
         1         2         3         4         5         6         7
1234567890123456789012345678901234567890123456789012345678901234567890
class Parser {
  public void register(TokenType token, PrefixParselet parselet) {
    mPrefixParselets.put(token, parselet);
  }

  public Expression parseExpression() {
    Token token = consume();
    PrefixParselet prefix = mPrefixParselets.get(token.getType());

    if (prefix == null) throw new ParseException(
        "Could not parse \"" + token.getText() + "\".");

    return prefix.parse(this, token);
  }

  // Other stuff...

  private final Map<TokenType, PrefixParselet> mPrefixParselets =
      new HashMap<TokenType, PrefixParselet>();
}
```

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed luctus suscipit elit mattis blandit. Sed dolor metus, fermentum vitae vestibulum ut, sollicitudin at tortor. Donec ac lobortis tortor. Proin id magna nisl. Pellentesque porttitor rutrum orci non dignissim. Morbi eros tortor, ultrices id aliquet quis, commodo ut purus. Suspendisse eget nunc lacus. In id sodales tortor.

## A Second Level Header

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed luctus suscipit elit mattis blandit. Sed dolor metus, fermentum vitae vestibulum ut, sollicitudin at tortor. Donec ac lobortis tortor. Proin id magna nisl. Pellentesque porttitor rutrum orci non dignissim. Morbi eros tortor, ultrices id aliquet quis, commodo ut purus. Suspendisse eget nunc lacus. In id sodales tortor.

### A Third Level Header

In metus magna, malesuada sit amet fermentum ac, porttitor ut tellus. Curabitur sit amet arcu orci. Phasellus euismod faucibus nisl nec ultricies. Nam nunc mi, porta venenatis pellentesque vitae, cursus a lectus. Morbi placerat accumsan condimentum. Pellentesque scelerisque volutpat felis a tristique.

* Nulla nulla odio, tincidunt vitae dignissim non, tempus sed felis. Morbi elementum nunc sit amet ipsum imperdiet sed dignissim felis congue.

* Cras porttitor commodo felis sit amet adipiscing.

    * Praesent ut malesuada risus. Nulla ac sapien sed dolor pulvinar placerat sit amet in diam. Nulla convallis pulvinar tortor id semper.

        Integer ut tellus velit, vel varius justo. Phasellus et metus sed purus blandit lobortis vel non ante. Aenean nec vestibulum turpis.

    * Phasellus vitae tortor augue, at porttitor augue. Sed placerat eleifend metus, sed lacinia ligula ullamcorper in. Integer lorem sem, rhoncus id sodales eu, tincidunt eu turpis. Nam vitae odio vitae lectus consequat euismod et vel orci. Vestibulum ligula turpis, porttitor sit amet tristique sed, scelerisque et purus. Nulla semper nibh non lacus blandit ac commodo lectus suscipit.

* Morbi sagittis tortor nec velit cursus eget rhoncus purus blandit.

Let's not forget numbered lists:

1. Praesent ut malesuada risus.

2. Nulla ac sapien sed dolor pulvinar placerat sit amet in diam.

3. Nulla convallis pulvinar tortor id semper.

    1. Integer ut tellus velit, vel varius justo.

    2. Phasellus et metus sed purus blandit lobortis vel non ante.

4. Aenean nec vestibulum turpis.

And now, a block quote:

> Phasellus vitae tortor augue, at porttitor augue. Sed placerat eleifend metus, sed lacinia ligula ullamcorper in. Integer lorem sem, rhoncus id sodales eu, tincidunt eu turpis. Nam vitae odio vitae lectus consequat euismod et vel orci. Vestibulum ligula turpis, porttitor sit amet tristique sed, scelerisque et purus. Nulla semper nibh non lacus blandit ac commodo lectus suscipit.

<p class="cite">Some Latin Dude</p>

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed luctus suscipit elit mattis blandit. Sed dolor metus, fermentum vitae vestibulum ut, sollicitudin at tortor. Donec ac lobortis tortor. Proin id magna nisl. Pellentesque porttitor rutrum orci non dignissim. Morbi eros tortor, ultrices id aliquet quis, commodo ut purus. Suspendisse eget nunc lacus. In id sodales tortor.

## And Now, Let's Have a Table

This is a paragraph right before it.

<div class="table">
<table>
<thead>
<tr>
<td class="right">Array Size</td>
<td class="right">SortTest</td>
<td class="right">SortTestT</td>
<td class="right">SortTestTC</td>
<td class="right">SortIndirect</td>
</tr>
</thead>
<tr>
<td class="right"><tt>1024</tt></td>
<td class="right"><tt>10.7162</tt></td>
<td class="right"><tt>2.3441</tt></td>
<td class="right"><tt>3.8781</tt></td>
<td class="right"><tt>1.1366</tt></td>
</tr>
<tr>
<td class="right"><tt>2048</tt></td>
<td class="right"><tt>22.9509</tt></td>
<td class="right"><tt>4.3889</tt></td>
<td class="right"><tt>8.4408</tt></td>
<td class="right"><tt>1.8714</tt></td>
</tr>
<tr>
<td class="right"><tt>4096</tt></td>
<td class="right"><tt>49.3709</tt></td>
<td class="right"><tt>8.4452</tt></td>
<td class="right"><tt>17.3883</tt></td>
<td class="right"><tt>3.7319</tt></td>
</tr>
<tr>
<td class="right"><tt>8192</tt></td>
<td class="right"><tt>103.5701</tt></td>
<td class="right"><tt>18.5369</tt></td>
<td class="right"><tt>38.1285</tt></td>
<td class="right"><tt>8.0310</tt></td>
</tr>
<tr>
<td class="right"><tt>16384</tt></td>
<td class="right"><tt>220.9323</tt></td>
<td class="right"><tt>39.6958</tt></td>
<td class="right"><tt>80.9258</tt></td>
<td class="right"><tt>18.5821</tt></td>
</tr>
<tr>
<td class="right"><tt>32768</tt></td>
<td class="right"><tt>469.5507</tt></td>
<td class="right"><tt>84.5129</tt></td>
<td class="right"><tt>172.2964</tt></td>
<td class="right"><tt>41.2126</tt></td>
</tr>
<tr>
<td class="right"><tt>65536</tt></td>
<td class="right"><tt>1016.2149</tt></td>
<td class="right"><tt>188.6718</tt></td>
<td class="right"><tt>380.3507</tt></td>
<td class="right"><tt>93.2924</tt></td>
</tr>
<tr>
<td class="right"><tt>131072</tt></td>
<td class="right"><tt>2156.4188</tt></td>
<td class="right"><tt>399.7299</tt></td>
<td class="right"><tt>791.6437</tt></td>
<td class="right"><tt>210.9526</tt></td>
</tr>
<tr>
<td class="right"><tt>262144</tt></td>
<td class="right"><tt>4616.3540</tt></td>
<td class="right"><tt>847.9829</tt></td>
<td class="right"><tt>1692.9814</tt></td>
<td class="right"><tt>467.6020</tt></td>
</tr>
<tr>
<td class="right"><tt>524288</tt></td>
<td class="right"><tt>9732.4311</tt></td>
<td class="right"><tt>1793.9729</tt></td>
<td class="right"><tt>3545.2089</tt></td>
<td class="right"><tt>1038.2164</tt></td>
</tr>
</table>
</div>

And another right after.
