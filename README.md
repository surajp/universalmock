# Apex Universal Mocker

A universal mocking class for Apex, built using the [Apex Stub API](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_stub_api.htm), subject to all its limitations. The api design choices for this class have been driven by a desire to make mocking as simple as possible for developers to understand and implement. It favors fluency and readability above everything else. Consequently, trade-offs have been made such as the limitation noted towards the end of this Readme.

## Installation

- Simply copy the `UniversalMocker.cls` to your org. The `examples` folder merely serves as a reference.

## Usage

### Setup

#### Basic Setup

- Create an instance of `UniversalMocker` for each class you want to mock.

  ```java
  UniversalMocker mockInstance = UniversalMocker.mock(AccountDBService.class);
  ```

- Set the mock values you want to return for each method.

  ```java
  mockInstance.when('getOneAccount').thenReturn(mockAccount);
  ```

- Use `withParamTypes` for overloaded methods.

```java
  mockInstance.when('getOneAccount').withParamTypes(new List<Type>{Id.class})
              .thenReturn(mockAccount);
```

- You can also set up a method to throw an exception

  ```java
  mockInstance.when('getOneAccount').thenThrow(new MyCustomException());
  ```

- Create an instance of the class you want to mock.

  ```java
  AccountDBService mockDBService = (AccountDBService)mockInstance.createStub();
  ```

#### Sequential Mocks

There might be instances where you may need the same method to mock different return values within the same test when
testing utility methods or selector classes and such. You can specify different return values based on the call count
in such cases

- Basic example

```java
  mockInstance.when('getOneAccount').thenReturnUntil(3,mockAccountOne).thenReturn(mockAccountTwo);
```

Here, `mockAccountOne` is returned the first 3 times `getOneAccount` is called. All subsequent calls to `getOneAccount`
will return `mockAccountTwo`

- You can also pair it with param types or to mock exceptions

```java
  mockInstance.when('getOneAccount').withParamTypes(new List<Type>{Id.class})
    .thenReturnUntil(1,mockAccountOne)
    .thenThrowUntil(3,mockException)
    .thenReturn(mockAccountTwo);
```

Refer to the [relevant unit tests](force-app/main/default/classes/example/AccountDomainTest.cls#L265) for further
clarity

**Note**: It is recommended that you end all setup method call chains with `thenReturn` or `thenThrow`

#### Mutating Arguments

There might be instances where you need to modify the original arguments passed into the function. A typical example
would be to set the `Id` field of records passed into a method responsible for inserting them.

- Create a class that implements the `UniversalMocker.Mutator` interface. The interface has a single method `mutate`
  with the following signature.

```java
  void mutate(
    Object stubbedObject, String stubbedMethodName,
    List<Type> listOfParamTypes, List<Object> listOfArgs
  );
```

Here's the method for setting fake ids on inserted records, in our example.

```java
  public void mutate(
    Object stubbedObject, String stubbedMethodName,
    List<Type> listOfParamTypes, List<Object> listOfArgs
  ) {
      Account record = (Account) listOfArgs[0];
      record.Id = this.getFakeId(Account.SObjectType);
  }
```

- Pass in an instance of your implementation of the `Mutator` class to mutate the method arguments.

```java
  mockInstance.when('doInsert').mutateWith(dmlMutatorInstance).thenReturnVoid();
```

Check out the [AccountDomainTest](./force-app/main/default/classes/example/AccountDomainTest.cls#L244) class for the
full example.

You can call the `mutateWith` method any number of times in succession, with the same or different mutator instances,
to create a chain of methods to mutate method arguments.

#### Sequential Mutators

You can also use specific mutators based on call count. Multiple mutators with the same value of call count will be
accumulated and applied in succession for all calls since the previous established call count.

For example, lets say you have a `DescriptionMutator` class as shown below. It appends a given string to the `Account
Description` field.

```java
  //Adds a given suffix to account description
  public class DescriptionMutator implements UniversalMocker.Mutator {
    private String stringToAdd = '';
    public DescriptionMutator(String stringToAdd) {
      this.stringToAdd = stringToAdd;
    }
    public void mutate(Object stubbedObject, String stubbedMethodName, List<Type> listOfParamTypes, List<Object> listOfArgs) {
      Account record = (Account) listOfArgs[0];
      if (record.get('Description') != null) {
        record.Description += this.stringToAdd;
      } else {
        record.Description = this.stringToAdd;
      }
    }
  }
```

If you wanted to append the string `12` to the Account Description for the first 2 calls and then the string `3` for all subsequent
calls, your setup would look something like:

```java
mockService.when(mockedMethodName).mutateUntil(2, new DescriptionMutator('1')).mutateUntil(2, new DescriptionMutator('2'))
.mutateWith(new DescriptionMutator('3'));
```

or

```java
mockService.when(mockedMethodName).mutateUntil(2, new DescriptionMutator('12')).mutateWith(new DescriptionMutator('3'));
```

If you wanted to append the string `1` to the Account Description for the first call, the string `2` for the second call,
and string `3` for all subsequent calls, your setup would look as follows:

```java
mockService.when(mockedMethodName).mutateUntil(1, new DescriptionMutator('1')).mutateUntil(2, new DescriptionMutator('2'))
.mutateWith(new DescriptionMutator('3'));
```

Check out the [AccountDomainTest](./force-app/main/default/classes/example/AccountDomainTest.cls#L193) class for the
full example.

### Verification

- Assert the exact number of times a method was called.

  ```java
  mockInstance.assertThat().method('getOneAccount').wasCalled(1);
  mockInstance.assertThat().method('getOneAccount').wasCalled(2);
  ```

- Assert if the number of times a method was called was more or less than a given integer.

  ```java
  mockInstance.assertThat().method('getOneAccount').wasCalled(1,UniversalMocker.Times.OR_MORE);
  mockInstance.assertThat().method('getOneAccount').wasCalled(1,UniversalMocker.Times.OR_LESS);
  ```

- Assert that a method was not called. This works both for methods that had mock return values set up before the test
  and for ones that didn't.

  ```java
  mockInstance.assertThat().method('dummyMethod').wasNeverCalled();
  ```

  Note that `mockInstance.assertThat().method('dummyMethod').wasCalled(0,UniversalMocker.Times.EXACTLY);` would only
  work if you had a mock return value set up for `dummyMethod` before running the test.

- Get the value of an argument passed into a method. Use `withParamTypes` for overloaded methods.

  ```java
  mockInstance.forMethod('doInsert').andInvocationNumber(0).getValueOf('acct');
  mockInstance.forMethod('doInsert').withParamTypes(new List<Type>{Account.class}).andInvocationNumber(0).getValueOf('acct');
  ```

  **Note**: If you use `mutateWith` to mutate the original method arguments, the values returned here are the mutated
  arguments and not the original method arguments.

## Notes

1. Method and argument names are case-insensitive.
2. If you don't have overloaded methods, it is recommended to not use `withParamTypes`. Conversely, if you do have overloaded methods,
   it is recommended that you do use `withParamTypes` for mocking as well as verification.
3. If you use `withParamTypes` for setting up the mock, you need to use it for verification and fetching method arguments as well.
4. It is highly recommended that you always verify the mocked method call counts to insulate against typos in method names being mocked and any future refactoring.
5. The glaring limitation in the current version is the inability to mock methods with exact arguments, so this may not work if that's what you're looking to do.
6. Although it is not recommended to test async behavior in unit tests since that is a platform feature, the library does support it.

## Contributions

Many thanks to my fellow [SFXD](https://sfxd.github.io/) members [@jamessimone](https://github.com/jamessimone) [@ThieveryShoe](https://github.com/Thieveryshoe) [@jlyon11](https://github.com/jlyon87) [@elements](https://github.com/elements) for their feedback and contribution.
