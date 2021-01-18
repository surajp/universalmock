# Apex Universal Mocker

A universal mocking class for Apex, built using the [Apex Stub API](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_stub_api.htm), subject to all its limitations. The api design choices for this class have been driven by a desire to make mocking as simple as possible for developers to understand and implement. It favors fluency and readability above everything else. Consequently, trade-offs have been made such as the limitation noted towards the end of this Readme. 

## Installation

- Simply copy the `UniversalMocker.cls` to your org. The `examples` folder merely serves as a reference.

## Usage

### Setup

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

#### Mutating arguments

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
Check out the [AccountDomainTest](./force-app/main/default/classes/example/AccountDomainTest.cls#L187) class for the 
full example.

- Pass in an instance of your implementation of the `Mutator` class to mutate the method arguments. Check out the 
complete test method [here](./force-app/main/default/classes/example/AccountDomainTest.cls#L146)

```java
  mockInstance.when('doInsert').mutateWith(dmlMutatorInstance).thenReturnVoid();
```

**Note**: You can call the `mutateWith` method any number of times in succession, with the same or different mutator instances,
to create a chain of methods to mutate method arguments.

### Verification

- Assert the number of times a method was called.

  ```java
  mockInstance.assertThat().method('getOneAccount').wasCalled(1,UniversalMocker.Times.EXACTLY);
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

## Contributions

Many thanks to my fellow [SFXD](https://sfxd.github.io/) members [@jamessimone](https://github.com/jamessimone) [@ThieveryShoe](https://github.com/Thieveryshoe) [@jlyon11](https://github.com/jlyon87) [@elements](https://github.com/elements) for their feedback and contribution.
