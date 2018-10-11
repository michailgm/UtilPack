﻿/*
 * Copyright 2017 Stanislav Muhametsin. All rights Reserved.
 *
 * Licensed  under the  Apache License,  Version 2.0  (the "License");
 * you may not use  this file  except in  compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed  under the  License is distributed on an "AS IS" BASIS,
 * WITHOUT  WARRANTIES OR CONDITIONS  OF ANY KIND, either  express  or
 * implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 */
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace UtilPack.AsyncEnumeration
{
   /// <summary>
   /// This is utility class for various empty asynchronous enumerables and enumerators.
   /// </summary>
   /// <typeparam name="T">The type of items being enumerated.</typeparam>
   public static class EmptyAsync<T>
   {
      private sealed class EmptyAsyncEnumerable : IAsyncEnumerable<T>
      {
         public IAsyncEnumerator<T> GetAsyncEnumerator()
            => Enumerator;

         public IAsyncEnumerable<T> GetWrappedSynchronousSource()
            => null;

         public IAsyncProvider AsyncProvider => DefaultAsyncProvider.Instance; // TODO optimized provider which would return EmptyAsync<>.Enumerable whenever possible.

      }

      private sealed class EmptyAsyncEnumerator : IAsyncEnumerator<T>
      {
         public Task<Boolean> WaitForNextAsync()
            => TaskUtils.False;

         public T TryGetNext( out Boolean success )
         {
            success = false;
            return default;
         }

         public Task DisposeAsync()
            => TaskUtils.CompletedTask;
      }

      /// <summary>
      /// Gets the <see cref="IAsyncEnumerator{T}"/> which will return no items.
      /// </summary>
      /// <value>The <see cref="IAsyncEnumerator{T}"/> which will return no items.</value>
      public static IAsyncEnumerator<T> Enumerator { get; } = new EmptyAsyncEnumerator();

      /// <summary>
      /// Gets the <see cref="IAsyncConcurrentEnumerable{T}"/> which will always return <see cref="IAsyncConcurrentEnumerable{T}"/> with no items.
      /// </summary>
      /// <value>The <see cref="IAsyncConcurrentEnumerable{T}"/> which will always return <see cref="IAsyncConcurrentEnumerable{T}"/> with no items.</value>
      public static IAsyncEnumerable<T> Enumerable { get; } = new EmptyAsyncEnumerable();


   }
}
