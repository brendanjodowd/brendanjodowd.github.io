---
layout: post
title: "Very simple arrays"
author: Brendan O'Dowd
---

Arrays are a convenient tool for handling several columns at once within a data step. They're often used for performing similar operations to multiple variables in a loop without having to duplicate code. An array can include character or numerical variables, but not both. I usually use arrays to handle a bunch of existing variables, but an array statement can also be used to create a series of new variables too. At the end of the data step all those variables will still exist, but their relationship to the array will not. 

Let's imagine a dataset called EARNINGS showing annual earnings (in thousands) for 5 people over 4 years.

<details>
  <summary>Click for datalines on table</summary>
  
{% highlight sas %}
    data EARNINGS;
  input name $ Year_1 Year_2 Year_3 Year_4;
  datalines;
Tom 25 28 30 32
May 45 45 45 45
Bob . . 27 30
Amy 31 33 . 35
Joe 60 55 65 70
;
run;
{% endhighlight %}
</details>

| Name | Year_1 | Year_2 | Year_3 |Year_4|
|:-- | --: | --: | --:| --:|
|Tom|25|28|30|32|
|May|45|45|45|45|
|Bob|.|.|27|30|
|Amy|31|33| .|35|
|Joe|60|55|65|70|

Here's a very basic array setup like what you'll see in an intro to arrays. We'll create an array called `earnings_array` which contains the earnings for each individual in each of the four years. Then we'll create a do loop which adds 5 to everyone's earnings in each year. At the end I've added `drop i;` because otherwise the indexing variable will be in the output, and we usually don't want that. 

{% highlight sas %}
data EARNINGS;
  set EARNINGS;
  array earnings_array {4} year_1 year_2 year_3 year_4;
  do i = 1 to 4;
    earnings_array[i] = earnings_array[i] + 5;
  end;
  drop i;
run;
{% endhighlight %}

There's a couple of points which can make this a little simpler and a little more flexible which are good to know. The first is that the length in the array statement (`{4}` above) is actually optional, you can leave it blank and SAS will figure out the length by how many variables are included. Often you will see the length as `{*}` which does the same thing. Conventionally the length is shown in curly brackets (like this: `{4}`) and the index is shown in square brackets (like this: `[i]`), but actually square, curly and normal brackets can be used interchangeably. 

The second thing that's good to know is that there are shortcuts for cases where you want to list an array of a series of numbered variables with a common prefix, like `year_1 year_2 year_3 year_4`. The first is to use `year:`, and this will include all variables that begin with the string "`year`". So like this:

{% highlight sas %}
data EARNINGS;
  set EARNINGS;
  array earnings_array year: ;
  /*etc etc*/
run;
{% endhighlight %}

One potential risk here is related to the order of the variables `year_X` in the original dataset. Let's suppose that for some reason the input dataset came in with `year_1` and `year_2` in reverse order, like this:

| Name | **Year_2**| **Year_1** | Year_3 |Year_4|
|:-- | --: | --: | --: | --:|
|Tom|**28**|**25**|30|32|
|...|...|...|...|...|


Now if you use `array earnings_array year: ;`, SAS will assume that the first entry in the array is `year_2` and the second is `year_1`. This could pose problems if you want to treat these years differently or if you're trying to return the index for a particular year based on the data. 

If you're not fully sure about the input order but you still don't want to list out all the variables (maybe there's hundreds of them), you can use:

{% highlight sas %}
data EARNINGS;
  set EARNINGS;
  array earnings_array year_1-year_4 ;
  /*etc etc*/
run;
{% endhighlight %}

One last thing on do loops that I use all the time: rather than specifying the end number of the loop (4 here) you can just write `dim(earnings_array)`, like this:

{% highlight sas %}
data EARNINGS;
  set EARNINGS;
  array earnings_array year: ;
  do i = 1 to dim(earnings_array);
    /*some manipulation*/
  end;
run;
{% endhighlight %}

This way your code can handle any number of entries in the array. Just be aware of assuming that the columns are in the right order, as mentioned earlier. 
