---
layout: post
title: "Very simple arrays"
author: Brendan O'Dowd
---

Arrays are a useful tool for handling several columns at once. They're particularly useful for performing similar operations to multiple variables without having to duplicate code. An array can include character or numerical variables, but not both. An array statement is done within a data step, and it associates a bunch of columns with an array name, with individual elements in the array can accessed via an index. At the end of the data step the array ceases to exist and those variables are no longer associated with the array name.

Let's imagine a table showing annual earnings (in thousands) for 5 people over 3 years.

| Name | Year_1 | Year_2 | Year_3 |
|--- | --- | --- | --- |
|Tom|25|28|30|32|
|Mary|45|45|45|45|
|Joe| | |27|30|
|Kate|31|33| |35|
|Ben|60|55|65|70|
