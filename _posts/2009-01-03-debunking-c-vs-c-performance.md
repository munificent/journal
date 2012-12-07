---
title: "Debunking C# vs C++ Performance"
categories: blog, c#, code, cpp, optimization
date: 2009/01/03
---
If you were on [reddit](http://www.reddit.com/r/programming/) today, you probably saw [this article](http://systematicgaming.wordpress.com/2009/01/03/performance-c-vs-c/),
damning C#'s performance as being **ten times worse than C++'s**. Holy shit
balls, batman!

Running his C# code, here are the results I got:

## Original C# Code

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

Pretty slow! So I took a look at the code. The first thing that would catch
the eye of any C# programmer is this:

    :::csharp
    unsafe struct Data
    {
        public int key;
        public fixed char data[128];
    }

*That's* the data structure he's sorting. An unsafe struct with a fixed array?
I had to look up `fixed` to even know what that *means*. Now, I understand
that he's trying to make an apples/apples comparison and keep the data
structure as close to the C++ one as possible, but I think that's missing the
point. If you're going to compare two languages, using their *built-in typical
sort functions*, shouldn't you use their typical *data structures* too? Here's
what how a regular C# developer would define `Data`:

    :::csharp
    class Data
    {
        public int key;
        public char[] data;

        public Data() { data = new char[128]; }
    }

No unmanaged code, no structs (which are rarely used in C#). Just a regular
class with an array. Here's the results:

## Modified to Typical C# Code

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
<td class="right"><tt>0.3605</tt></td>
<td class="right"><tt>0.3626</tt></td>
<td class="right"><tt>0.4150</tt></td>
<td class="right"><tt>0.5918</tt></td>
</tr>
<tr>
<td class="right"><tt>2048</tt></td>
<td class="right"><tt>0.7651</tt></td>
<td class="right"><tt>0.7446</tt></td>
<td class="right"><tt>0.8749</tt></td>
<td class="right"><tt>0.5021</tt></td>
</tr>
<tr>
<td class="right"><tt>4096</tt></td>
<td class="right"><tt>1.6434</tt></td>
<td class="right"><tt>1.6094</tt></td>
<td class="right"><tt>1.9468</tt></td>
<td class="right"><tt>1.2030</tt></td>
</tr>
<tr>
<td class="right"><tt>8192</tt></td>
<td class="right"><tt>3.6497</tt></td>
<td class="right"><tt>3.5216</tt></td>
<td class="right"><tt>4.1014</tt></td>
<td class="right"><tt>2.3926</tt></td>
</tr>
<tr>
<td class="right"><tt>16384</tt></td>
<td class="right"><tt>7.9555</tt></td>
<td class="right"><tt>8.0842</tt></td>
<td class="right"><tt>9.3324</tt></td>
<td class="right"><tt>5.4752</tt></td>
</tr>
<tr>
<td class="right"><tt>32768</tt></td>
<td class="right"><tt>21.1833</tt></td>
<td class="right"><tt>19.1183</tt></td>
<td class="right"><tt>23.1170</tt></td>
<td class="right"><tt>15.1998</tt></td>
</tr>
<tr>
<td class="right"><tt>65536</tt></td>
<td class="right"><tt>54.6938</tt></td>
<td class="right"><tt>53.4892</tt></td>
<td class="right"><tt>72.3932</tt></td>
<td class="right"><tt>34.6554</tt></td>
</tr>
<tr>
<td class="right"><tt>131072</tt></td>
<td class="right"><tt>122.5008</tt></td>
<td class="right"><tt>114.1937</tt></td>
<td class="right"><tt>141.3504</tt></td>
<td class="right"><tt>75.9064</tt></td>
</tr>
<tr>
<td class="right"><tt>262144</tt></td>
<td class="right"><tt>279.8014</tt></td>
<td class="right"><tt>262.5908</tt></td>
<td class="right"><tt>343.4204</tt></td>
<td class="right"><tt>160.8344</tt></td>
</tr>
<tr>
<td class="right"><tt>524288</tt></td>
<td class="right"><tt>598.5605</tt></td>
<td class="right"><tt>577.7487</tt></td>
<td class="right"><tt>759.4405</tt></td>
<td class="right"><tt>359.7824</tt></td>
</tr>
</table>
</div>

Let's compare the last lines of each:

<div class="table">
<table>
<thead>
<tr>
<td>Data Type</td>
<td class="right">SortTest</td>
<td class="right">SortTestT</td>
<td class="right">SortTestTC</td>
<td class="right">SortIndirect</td>
</tr>
</thead>
<tr>
<td>struct/fixed</td>
<td class="right"><tt>9732.4311</tt></td>
<td class="right"><tt>1793.9729</tt></td>
<td class="right"><tt>3545.2089</tt></td>
<td class="right"><tt>1038.2164</tt></td>
</tr>
<tr>
<td>class</td>
<td class="right"><tt>598.5605</tt></td>
<td class="right"><tt>577.7487</tt></td>
<td class="right"><tt>759.4405</tt></td>
<td class="right"><tt>359.7824</tt></td>
</tr>
<tr>
<td>how much faster</td>
<td class="right"><tt><b>16.259x</b></tt></td>
<td class="right"><tt><b>3.105x</b></tt></td>
<td class="right"><tt><b>4.668x</b></tt></td>
<td class="right"><tt><b>2.885x</b></tt></td>
</tr>
</table>
</div>

Um, *slightly* different? In his original post, he states that the indirect
sorting is twice as fast in C++ than in C#. I can't do a direct comparison
since I didn't run the C++ code, but since my change to the C# made it run
2.885 times faster than his C# code, it stands to reason that the **C# and C++
performance are neck and neck, if not a bit faster in C#**.

## Apples to Oranges to Avocados

If you're rooting for the C++ side, you're probably thinking, "No fair! The C#
one didn't have to move the whole array around in memory!" Well, yeah, it
didn't: *because that's how C# programmers use the language*. Since it's safe
to rely on the garbage collector to handle deallocations, C# programmers don't
spend effort avoiding using "dangerous" pointers (i.e. reference types). This
is simply how the language is used. To me, the fairest comparison is one that
preserves both the procedures (which he did by using the built-in sorts) *and*
the data structures (which he did not do) used by each language.

## The Code

Aside from the `Data` change above, I cleaned up some of the copy and paste in
his code. Here's what I used:

    :::csharp
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Text;
    using System.Runtime.InteropServices;

    namespace CachePressureCS
    {
        // normal c# type
        class Data
        {
            public int key;
            public char[] data;

            public Data() { data = new char[128]; }
        }

        class DataComparer : IComparer
        {
            int IComparer.Compare(Object x, Object y)
            {
                return ((Data)x).key - ((Data)y).key;
            }
        }

        class DataComparerT : IComparer<Data>
        {
            public int Compare(Data x, Data y)
            {
                return x.key - y.key;
            }
        }

        class Timer
        {
            [DllImport("Kernel32.dll")]
            private static extern bool QueryPerformanceCounter(out long counter);

            [DllImport("Kernel32.dll")]
            private static extern bool QueryPerformanceFrequency(out long frequency);

            public Timer()
            {
                mStart = mEnd = 0;
                QueryPerformanceFrequency(out mFrequency);
            }

            public void Start() { QueryPerformanceCounter(out mStart); }

            public void End() { QueryPerformanceCounter(out mEnd); }

            public double Time
            {
                get { return 1000.0 * (double)(mEnd - mStart) / (double)mFrequency; }
            }

            long mFrequency;
            long mStart;
            long mEnd;
        }

        class Program
        {
            static int CompareData(Data x, Data y)
            {
                return x.key - y.key;
            }

            static Data[] MakeData(int size)
            {
                Random rng = new Random(0);
                Data[] data = new Data[size];

                for (int i = 0; i < data.Length; i++)
                {
                    data[i] = new Data();
                    data[i].key = rng.Next();
                }

                return data;
            }

            static double Test(int size, Action<Data[]> sort)
            {
                Timer time = new Timer();
                Data[] data = MakeData(size);

                time.Start();
                sort(data);
                time.End();

                return time.Time;
            }

            static double SortTest(int size)
            {
                return Test(size, data => Array.Sort(data, new DataComparer()));
            }

            static double SortTestT(int size)
            {
                return Test(size, data => Array.Sort<Data>(data, new DataComparerT()));
            }

            static double SortTestTC(int size)
            {
                return Test(size, data => Array.Sort<Data>(data, CompareData));
            }

            static double SortTestC(int size)
            {
                return Test(size, data => Array.Sort(data, CompareData));
            }

            static double SortTestIndirect(int size)
            {
                Random rng = new Random(0);
                Timer time = new Timer();
                Data[] data = new Data[size];
                int[] indirect = new int[size];

                for (int i = 0; i < data.Length; i++)
                {
                    data[i] = new Data();
                    data[i].key = rng.Next();
                    indirect[i] = data[i].key;
                }

                time.Start();
                Array.Sort<int, Data>(indirect, data);
                time.End();

                return time.Time;
            }

            private static void Time(Func<int, double> fn, int size)
            {
                double time = 0;
                for (int j = 0; j < 10; j++)
                {
                    time += fn(size);
                }
                time /= 10.0;

                Console.Write("{0,14:F4}", time);
            }

            static void Main(string[] args)
            {
                Console.WriteLine("    size      SortTest     SortTestT    SortTestTC  SortIndirect");
                Console.WriteLine("-------- ------------- ------------- ------------- -------------");

                for (int i = 0; i < 10; i++)
                {
                    int size = 1024 << i;

                    Console.Write("{0,8}", size);
                    Time(SortTest, size);
                    Time(SortTestT, size);
                    Time(SortTestTC, size);
                    Time(SortTestIndirect, size);

                    Console.WriteLine();
                }

                Console.ReadKey();
            }
        }
    }
