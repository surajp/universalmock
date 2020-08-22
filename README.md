# Apex Universal Mocker

A universal mocking class for Apex.

## Usage

1. Create an instance of `UniversalMocker` for each class you want to mock.

  ```java
  UniversalMocker mockInstance = UniversalMocker.mock(AccountDBService.class);
  ```
  
2. Set mock values you want to return for each method. Use `withParamTypes` for overloaded methods.

  ```java
  mockInstance.when('getOneAccount').thenReturn(mockAccount);
  mockInstance.when('getOneAccount').withParamTypes(new List<Type>{Id.class})
              .thenReturn(mockAccount);
  ```

3. Create an instance of the class you want to mock, using an instance of `UniversalMocker` and Apex Stub API

  ```java
  AccountDBService mockDBService = (AccountDBService)Test
                                    .createStub(AccountDBService.class,mockInstance);
  ```
  
3. Assert number of times a method was called.

  ```java
  mockInstance.assertThat().method('getOneAccount').wasCalled(1).times();
  ```

4. Get the argument passed into a method. Use `withParamTypes` for overloaded methods.

  ```java
  mockInstance.forMethod('doInsert').andInvocatioNumber(0).getValueOf('acct');
  ```

