---
title: "Debunking C# vs C++ Performance"
categories: c-sharp code cpp optimization
---

If you were on [reddit][] today, you probably saw [this article][], damning C#'s
performance as being **ten times worse than C++'s**. Holy shit balls, batman!

[reddit]: http://www.reddit.com/r/programming/
[this article]: http://systematicgaming.wordpress.com/2009/01/03/performance-c-vs-c/

Running his C# code, here are the results I got:

## Original C# code

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
<td class="right">1024</td>
<td class="right">10.7162</td>
<td class="right">2.3441</td>
<td class="right">3.8781</td>
<td class="right">1.1366</td>
</tr>
<tr>
<td class="right">2048</td>
<td class="right">22.9509</td>
<td class="right">4.3889</td>
<td class="right">8.4408</td>
<td class="right">1.8714</td>
</tr>
<tr>
<td class="right">4096</td>
<td class="right">49.3709</td>
<td class="right">8.4452</td>
<td class="right">17.3883</td>
<td class="right">3.7319</td>
</tr>
<tr>
<td class="right">8192</td>
<td class="right">103.5701</td>
<td class="right">18.5369</td>
<td class="right">38.1285</td>
<td class="right">8.0310</td>
</tr>
<tr>
<td class="right">16384</td>
<td class="right">220.9323</td>
<td class="right">39.6958</td>
<td class="right">80.9258</td>
<td class="right">18.5821</td>
</tr>
<tr>
<td class="right">32768</td>
<td class="right">469.5507</td>
<td class="right">84.5129</td>
<td class="right">172.2964</td>
<td class="right">41.2126</td>
</tr>
<tr>
<td class="right">65536</td>
<td class="right">1016.2149</td>
<td class="right">188.6718</td>
<td class="right">380.3507</td>
<td class="right">93.2924</td>
</tr>
<tr>
<td class="right">131072</td>
<td class="right">2156.4188</td>
<td class="right">399.7299</td>
<td class="right">791.6437</td>
<td class="right">210.9526</td>
</tr>
<tr>
<td class="right">262144</td>
<td class="right">4616.3540</td>
<td class="right">847.9829</td>
<td class="right">1692.9814</td>
<td class="right">467.6020</td>
</tr>
<tr>
<td class="right">524288</td>
<td class="right">9732.4311</td>
<td class="right">1793.9729</td>
<td class="right">3545.2089</td>
<td class="right">1038.2164</td>
</tr>
</table>
</div>

Pretty slow! So I took a look at the code. The first thing that would catch the
eye of any C# programmer is this:

```csharp
unsafe struct Data
{
    public int key;
    public fixed char data[128];
}
```

*That's* the data structure he's sorting. An unsafe struct with a fixed array? I
had to look up `fixed` to even know what that *means*. Now, I understand that
he's trying to make an apples/apples comparison and keep the data structure as
close to the C++ one as possible, but I think that's missing the point. If
you're going to compare two languages, using their *built-in typical sort
functions*, shouldn't you use their typical *data structures* too? Here's how a
regular C# developer would define `Data`:

```csharp
class Data
{
    public int key;
    public char[] data;

    public Data() { data = new char[128]; }
}
```

No unmanaged code, no structs (which are rarely used in C#). Just a regular
class with an array. Here's the results:

## Modified to typical C# code

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
<td class="right">1024</td>
<td class="right">0.3605</td>
<td class="right">0.3626</td>
<td class="right">0.4150</td>
<td class="right">0.5918</td>
</tr>
<tr>
<td class="right">2048</td>
<td class="right">0.7651</td>
<td class="right">0.7446</td>
<td class="right">0.8749</td>
<td class="right">0.5021</td>
</tr>
<tr>
<td class="right">4096</td>
<td class="right">1.6434</td>
<td class="right">1.6094</td>
<td class="right">1.9468</td>
<td class="right">1.2030</td>
</tr>
<tr>
<td class="right">8192</td>
<td class="right">3.6497</td>
<td class="right">3.5216</td>
<td class="right">4.1014</td>
<td class="right">2.3926</td>
</tr>
<tr>
<td class="right">16384</td>
<td class="right">7.9555</td>
<td class="right">8.0842</td>
<td class="right">9.3324</td>
<td class="right">5.4752</td>
</tr>
<tr>
<td class="right">32768</td>
<td class="right">21.1833</td>
<td class="right">19.1183</td>
<td class="right">23.1170</td>
<td class="right">15.1998</td>
</tr>
<tr>
<td class="right">65536</td>
<td class="right">54.6938</td>
<td class="right">53.4892</td>
<td class="right">72.3932</td>
<td class="right">34.6554</td>
</tr>
<tr>
<td class="right">131072</td>
<td class="right">122.5008</td>
<td class="right">114.1937</td>
<td class="right">141.3504</td>
<td class="right">75.9064</td>
</tr>
<tr>
<td class="right">262144</td>
<td class="right">279.8014</td>
<td class="right">262.5908</td>
<td class="right">343.4204</td>
<td class="right">160.8344</td>
</tr>
<tr>
<td class="right">524288</td>
<td class="right">598.5605</td>
<td class="right">577.7487</td>
<td class="right">759.4405</td>
<td class="right">359.7824</td>
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
<td class="right">9732.4311</td>
<td class="right">1793.9729</td>
<td class="right">3545.2089</td>
<td class="right">1038.2164</td>
</tr>
<tr>
<td>class</td>
<td class="right">598.5605</td>
<td class="right">577.7487</td>
<td class="right">759.4405</td>
<td class="right">359.7824</td>
</tr>
<tr>
<td>how much faster</td>
<td class="right"><b>16.259x</b></td>
<td class="right"><b>3.105x</b></td>
<td class="right"><b>4.668x</b></td>
<td class="right"><b>2.885x</b></td>
</tr>
</table>
</div>

Um, *slightly* different? In his original post, he states that the indirect
sorting is twice as fast in C++ than in C#. I can't do a direct comparison
since I didn't run the C++ code, but since my change to the C# made it run
2.885 times faster than his C# code, it stands to reason that the **C# and C++
performance are neck and neck, if not a bit faster in C#**.

## Apples to oranges to avocados

If you're rooting for the C++ side, you're probably thinking, "No fair! The C#
one didn't have to move the whole array around in memory!" Well, yeah, it
didn't: *because that's how C# programmers use the language*. Since it's safe
to rely on the garbage collector to handle deallocations, C# programmers don't
spend effort avoiding using "dangerous" pointers (i.e. reference types). This
is simply how the language is used. To me, the fairest comparison is one that
preserves both the procedures (which he did by using the built-in sorts) *and*
the data structures (which he did not do) used by each language.

## The code

Aside from the `Data` change above, I cleaned up some of the copy and paste in
his code. Here's what I used:

```csharp
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
        private static extern bool QueryPerformanceCounter(
            out long counter);

        [DllImport("Kernel32.dll")]
        private static extern bool QueryPerformanceFrequency(
            out long frequency);

        public Timer()
        {
            mStart = mEnd = 0;
            QueryPerformanceFrequency(out mFrequency);
        }

        public void Start() { QueryPerformanceCounter(out mStart); }

        public void End() { QueryPerformanceCounter(out mEnd); }

        public double Time
        {
            get {
                return 1000.0 * (double)(mEnd - mStart) /
                    (double)mFrequency;
            }
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
            return Test(size, data =>
                Array.Sort(data, new DataComparer()));
        }

        static double SortTestT(int size)
        {
            return Test(size, data =>
                Array.Sort<Data>(data, new DataComparerT()));
        }

        static double SortTestTC(int size)
        {
            return Test(size, data =>
                Array.Sort<Data>(data, CompareData));
        }

        static double SortTestC(int size)
        {
            return Test(size, data =>
                Array.Sort(data, CompareData));
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
            Console.WriteLine("    size      SortTest     SortTestT" +
                "    SortTestTC  SortIndirect");
            Console.WriteLine("-------- ------------- " +
                "------------- ------------- -------------");

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
```
