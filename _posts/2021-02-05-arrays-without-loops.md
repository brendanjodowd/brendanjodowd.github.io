---
layout: post
title: "Arrays without loops"
author: Brendan O'Dowd
---

This post highlights some neat uses of arrays which don't involve loops. 

Let's imagine we're dealing with the same EARNINGS dataset as the previous post:

| Name | Year_1 | Year_2 | Year_3 |Year_4|
|--- | --- | --- | --- | ---|
|Tom|25|28|30|32|
|Mary|45|45|45|45|
|Joe| | |27|30|
|Kate|31|33| |35|
|Ben|60|55|65|70|

We'll start with some simple functions like `sum()` and `mean()`. There is also `min()`, `max()`, `median()` and several others which work in the same way. Note the structure which includes `of` and `[*]` to indicate the whole array. The last function `coalesce()` is not so obvious; it returns the first non-missing entry in the array, which is the first column for everyone and 27 for Joe. It can be applied to array of numerical variables, there is a function called `coalescec()` for character arrays. 

{% highlight sas %}
data EARNINGS;
  set EARNINGS;
  array income_array year1-year4;
  total_income = sum(of income_array[*]);
  mean_income = mean(of income_array[*]);
  first_income = coalesce(of income_array[*]);
run;
{% endhighlight %}
