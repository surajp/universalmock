# Apex Universal Mocker

A universal mocking class for Apex.

## Usage

1. Create an instance of `UniversalMocker` for each class you want to mock.

  `UniversalMocker mockInstance = UniversalMocker.mock(AccountDBService.class);`
  
2. Set mock values you want to return for each method. Use `withParamTypes` for overloaded methods.

  `mockInstance.when('getOneAccount').thenReturn(mockAccount);`

  `mockInstance.when('getOneAccount').withParamTypes(new List<Type>{Id.class}).thenReturn(mockAccount);`
  
3. Assert number of times a method was called.

  `mockInstance.assertThat().method('getOneAccount').wasCalled(1).times();`

4. Get the argument passed into a method. Use `withParamTypes` for overloaded methods.

  `mockInstance.forMethod('doInsert').andInvocatioNumber(0).getArgument('acct').value();`

