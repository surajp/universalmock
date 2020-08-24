# Apex Universal Mocker

A universal mocking class for Apex, built using the [Apex Stub API](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_stub_api.htm), subject to all its limitations.

## Usage

### Setup

- Create an instance of `UniversalMocker` for each class you want to mock.

  ```java
  UniversalMocker mockInstance = UniversalMocker.mock(AccountDBService.class);
  ```
  
- Set mock values you want to return for each method. Use `withParamTypes` for overloaded methods.

  ```java
  mockInstance.when('getOneAccount').thenReturn(mockAccount);
  mockInstance.when('getOneAccount').withParamTypes(new List<Type>{Id.class})
              .thenReturn(mockAccount);
  ```

- Create an instance of the class you want to mock.

  ```java
  AccountDBService mockDBService = (AccountDBService)mock.createStub();
  ```
  
### Verification

- Assert number of times a method was called.

  ```java
  mockInstance.assertThat().method('getOneAccount').wasCalled(1).timesExactly();
  ```

- Get the argument passed into a method. Use `withParamTypes` for overloaded methods.

  ```java
  mockInstance.forMethod('doInsert').andInvocatioNumber(0).getValueOf('acct');
  ```

## Notes

1. Method and argument names are case-insensitive.
2. If you don't have overloaded methods, it is recommended to not use `withParamTypes`. Conversely, if you do have overloaded methods,
 it is recommended that you do use `withParamTypes` for mocking as well as verification.
3. If you use `withParamTypes` for setting up the mock, you need to use it for verification and fetching method arguments as well.

