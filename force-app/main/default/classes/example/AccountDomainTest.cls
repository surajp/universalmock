@IsTest
public with sharing class AccountDomainTest {
  private static final UniversalMocker mockService;
  private static final AccountDBService mockServiceStub;
  private static final AccountDomain sut; // system under test

  static {
    mockService = UniversalMocker.mock(AccountDBService.class); //This is the service we are mocking
    mockServiceStub = (AccountDBService) mockService.createStub();
    sut = new AccountDomain(mockServiceStub); //This is the class into which we inject our mocked service
  }

  @IsTest
  public static void it_should_return_one_account() {
    //setup
    String mockedMethodName = 'getOneAccount';
    Account mockAccount = new Account(Name = 'Mock Account');

    mockService.when(mockedMethodName).thenReturn(mockAccount);

    //test
    Test.startTest();
    Account accountDetail = sut.getAccountDetail();
    Test.stopTest();

    //verify
    system.assertEquals(mockAccount.Name, accountDetail.Name);
    mockService.assertThat().method(mockedMethodName).wasCalled(1);
  }

  @IsTest
  public static void it_should_create_a_public_account() {
    //setup
    String mockedMethodName = 'doInsert';

    //test
    Test.startTest();
    sut.createPublicAccount('Mock Account');
    Test.stopTest();

    //verify
    Account newAccount = (Account) mockService.forMethod(mockedMethodName).andInvocationNumber(0).getValueOf('acct');
    system.assertEquals('Mock Account', newAccount.Name);
    system.assertEquals('Public', newAccount.Ownership);
  }

  @IsTest
  public static void it_should_verify_call_counts_correctly() {
    //setup
    String mockedMethodName = 'getOneAccount';
    Account mockAccount = new Account(Name = 'Mock Account');

    mockService.when(mockedMethodName).thenReturn(mockAccount);
    mockService.when('mockedDummyMethod').thenReturn(null);

    //test
    Test.startTest();
    Account accountDetail = sut.getAccountDetail();
    sut.getAccountDetail();
    Test.stopTest();

    //verify
    system.assertEquals(mockAccount.Name, accountDetail.Name);
    mockService.assertThat().method(mockedMethodName).wasCalled(1, UniversalMocker.Times.OR_MORE);
    mockService.assertThat().method(mockedMethodName).wasCalled(2, UniversalMocker.Times.OR_MORE);
    mockService.assertThat().method(mockedMethodName).wasCalled(2);
    mockService.assertThat().method(mockedMethodName).wasCalled(2, UniversalMocker.Times.OR_LESS);
    mockService.assertThat().method(mockedMethodName).wasCalled(3, UniversalMocker.Times.OR_LESS);
    mockService.assertThat().method('mockedDummyMethod').wasNeverCalled();
    mockService.assertThat().method('nonMockedDummyMethod').wasNeverCalled();
  }

  @IsTest
  public static void it_should_call_overloaded_methods_correctly() {
    //setup
    String mockedMethodName = 'getMatchingAccounts';
    Account acctOne = new Account(Name = 'Account with matching Id');
    Account acctTwo = new Account(Name = 'Account with matching name');

    mockService.when(mockedMethodName).withParamTypes(new List<Type>{ Id.class }).thenReturn(new List<Account>{ acctOne });
    mockService.when(mockedMethodName).withParamTypes(new List<Type>{ String.class }).thenReturn(new List<Account>{ acctTwo });

    //test
    Test.startTest();
    Id mockAccountId = '001000000000001';
    List<Account> acctsWithMatchingId = sut.getMatchingAccounts(mockAccountId);
    List<Account> acctsWithMatchingName = sut.getMatchingAccounts('Account with matching name');
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).withParamTypes(new List<Type>{ Id.class }).wasCalled(1);
    mockService.assertThat().method(mockedMethodName).withParamTypes(new List<Type>{ String.class }).wasCalled(1);
    Id accountIdParam = (Id) mockService.forMethod(mockedMethodName).withParamTypes(new List<Type>{ Id.class }).andInvocationNumber(0).getValueOf('accountId');
    String acctNameParam = (String) mockService.forMethod(mockedMethodName)
      .withParamTypes(new List<Type>{ String.class })
      .andInvocationNumber(0)
      .getValueOf('accountName');

    System.assertEquals(mockAccountId, accountIdParam);
    System.assertEquals('Account with matching name', acctNameParam);
    System.assertEquals(acctOne.Name, acctsWithMatchingId[0].Name);
    System.assertEquals(acctTwo.Name, acctsWithMatchingName[0].Name);
  }

  @IsTest
  public static void shouldResetMethodAndParamsAfterEachChain() {
    //setup
    String mockedMethodName = 'getMatchingAccounts';
    String newMethodName = 'getOneAccount';
    Account acctOne = new Account(Name = 'Account with matching Id');
    Account acctTwo = new Account(Name = 'Account with matching name');

    mockService.when(mockedMethodName).withParamTypes(new List<Type>{ Id.class }).thenReturn(new List<Account>{ acctOne });
    mockService.when(newMethodName).thenReturn(acctTwo); //This method takes no params. So by mocking this we attempt to ensure that the param type list from previous mock call (Id.class) has been cleared out

    //test
    Test.startTest();
    Id mockAccountId = '001000000000001';
    List<Account> acctsWithMatchingId = sut.getMatchingAccounts(mockAccountId);
    Account anotherAccount = sut.getAccountDetail();
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).withParamTypes(new List<Type>{ Id.class }).wasCalled(1);
    mockService.assertThat().method(newMethodName).wasCalled(1);

    System.assertEquals(acctOne.Name, acctsWithMatchingId[0].Name);
    System.assertEquals(acctTwo.Name, anotherAccount.Name);

    Id acctIdParam = (Id) mockService.forMethod(mockedMethodName).withParamTypes(new List<Type>{ Id.class }).getValueOf('accountId');
    Map<String, Object> argsMap = mockService.forMethod(newMethodName).getArgumentsMap();
    Assert.areEqual(mockAccountId, acctIdParam);
    Assert.areEqual(0, argsMap.size());
  }

  @IsTest
  public static void it_should_throw_mock_exception() {
    //setup
    String mockedMethodName = 'doInsert';
    String mockExceptionMessage = 'Mock exception';
    AuraHandledException mockException = new AuraHandledException(mockExceptionMessage);
    /*https://salesforce.stackexchange.com/questions/122657/testing-aurahandledexceptions*/
    mockException.setMessage(mockExceptionMessage);

    mockService.when(mockedMethodName).thenThrow(mockException);

    //test
    Test.startTest();
    boolean hasException = false;
    try {
      sut.createPublicAccount('Mock Account');
    } catch (AuraHandledException ex) {
      System.assertEquals(mockExceptionMessage, ex.getMessage());
      hasException = true;
    }
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).wasCalled(1);
    System.assert(hasException, 'Mocked exception was not thrown');
  }

  @IsTest
  public static void it_should_generate_unique_guids() {
    Integer numInstances = 20000;
    for (Integer i = 0; i < numInstances; i++) {
      UniversalMocker uMock = UniversalMocker.mock(AccountDBService.class);
    }
    System.assertEquals(numInstances + 1, UniversalMocker.uMockInstances.size(), 'We have collision in the generated guids'); //numInstances + 1 generated in the static block above
  }

  @IsTest
  public static void it_should_track_call_counts_across_queueables() {
    String mockedMethodName = 'doInsert';
    String mockExceptionMessage = 'Mock exception';
    UniversalMocker.Mutator dmlMutatorInstance = new DMLMutator();

    mockService.when(mockedMethodName).mutateWith(dmlMutatorInstance).thenReturnVoid();
    AccountsQueuable queueableSut = new AccountsQueuable(sut);

    //test
    Test.startTest();
    System.enqueueJob(queueableSut);
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).wasCalled(1);
    Account acct = (Account) mockService.forMethod(mockedMethodName).getValueOf('acct');
    System.assertNotEquals(null, acct.Id, 'Account Id is null after insert');
  }

  @IsTest
  public static void shouldApplyMutatorsBasedOnCallCounts() {
    String mockedMethodName = 'doUpdate';
    String mockExceptionMessage = 'Mock exception';
    UniversalMocker.Mutator dmlMutatorInstance = new DMLMutator();

    mockService.when(mockedMethodName).mutateUntil(1, new DescriptionMutator('1')).thenReturnVoid();

    Account acct = new Account(Name = 'Acme Inc');
    sut.updateAccount(acct);
    sut.updateAccount(acct);
    sut.updateAccount(acct);

    //verify
    mockService.assertThat().method(mockedMethodName).wasCalled(3);
    Assert.areEqual('1', acct.Description, 'Expected description to only be set once (till callcount 1)');

    mockService.resetState();
    acct.Description = ''; //reset account description
    mockService.when(mockedMethodName)
      .mutateUntil(2, new DescriptionMutator('1'))
      .mutateUntil(2, new DescriptionMutator('2'))
      .mutateWith(new DescriptionMutator('3'))
      .thenReturnVoid();
    sut.updateAccount(acct);
    sut.updateAccount(acct);
    sut.updateAccount(acct);
    Assert.areEqual(
      '12123',
      acct.Description,
      'Expected description to set to "12123" ("12" appended for each of the first two calls and "3" appended for the third call'
    );
  }

  @IsTest
  public static void it_should_track_call_counts_with_batchables() {
    String mockedMethodName = 'getOneAccount';
    Account mockAccount = new Account(Name = 'Mock Account');
    mockService.when(mockedMethodName).thenReturn(mockAccount);

    AccountsBatch batchableSut = new AccountsBatch(sut);

    //test
    Test.startTest();
    Database.executeBatch(batchableSut, 1);
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).wasCalled(1);
  }

  @IsTest
  public static void it_should_mutate_arguments() {
    //setup
    String mockedMethodName = 'doInsert';
    String mockExceptionMessage = 'Mock exception';
    UniversalMocker.Mutator dmlMutatorInstance = new DMLMutator();

    mockService.when(mockedMethodName).mutateWith(dmlMutatorInstance).thenReturnVoid();

    //test
    Test.startTest();
    boolean hasException = false;
    try {
      sut.createPublicAccount('Mock Account');
    } catch (AuraHandledException ex) {
      System.assertEquals(mockExceptionMessage, ex.getMessage());
      hasException = true;
    }
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).wasCalled(1);
    System.assert(!hasException, 'Mocked exception was not thrown');
    Account acct = (Account) mockService.forMethod('doInsert').getValueOf('acct');
    System.assertNotEquals(null, acct.Id, 'Account Id is null after insert');
  }

  @IsTest
  public static void it_should_handle_multiple_return_values_basic() {
    //setup
    String mockedMethodName = 'getOneAccount';
    Account mockAccountOne = new Account(Name = 'Mock Account One');
    Account mockAccountTwo = new Account(Name = 'Mock Account Two');

    mockService.when(mockedMethodName).thenReturnUntil(1, mockAccountOne).thenReturn(mockAccountTwo);

    //test
    Test.startTest();
    Account accountDetail = sut.getAccountDetail();
    Assert.areEqual(mockAccountOne.Name, accountDetail.Name);

    accountDetail = sut.getAccountDetail();
    Assert.areEqual(mockAccountTwo.Name, accountDetail.Name);

    //should return mockAccountTwo for all subsequent calls
    for (Integer i = 0; i < 100; i++) {
      accountDetail = sut.getAccountDetail();
    }
    Assert.areEqual(mockAccountTwo.Name, accountDetail.Name);
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).wasCalled(102);
  }

  @IsTest
  public static void it_should_handle_multiple_return_values_advanced() {
    //setup
    String mockedMethodName = 'getOneAccount';
    Account mockAccountOne = new Account(Name = 'Mock Account One');
    Account mockAccountTwo = new Account(Name = 'Mock Account Two');
    Account mockAccountThree = new Account(Name = 'Mock Account Three');

    //returns mockAccountOne for the first call, mockAccountTwo for the next 2 calls, and mockAccountThree for all subsequent calls
    mockService.when(mockedMethodName).thenReturnUntil(1, mockAccountOne).thenReturnUntil(3, mockAccountTwo).thenReturn(mockAccountThree);

    //test
    Test.startTest();
    Account accountDetail = sut.getAccountDetail();
    Assert.areEqual(mockAccountOne.Name, accountDetail.Name);

    accountDetail = sut.getAccountDetail();
    Assert.areEqual(mockAccountTwo.Name, accountDetail.Name);

    accountDetail = sut.getAccountDetail();
    Assert.areEqual(mockAccountTwo.Name, accountDetail.Name);

    accountDetail = sut.getAccountDetail();
    Assert.areEqual(mockAccountThree.Name, accountDetail.Name);

    //should return mockAccountTwo for all subsequent calls
    for (Integer i = 0; i < 100; i++) {
      accountDetail = sut.getAccountDetail();
    }
    Assert.areEqual(mockAccountThree.Name, accountDetail.Name);
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).wasCalled(104);
  }

  @IsTest
  public static void it_should_handle_multiple_return_values_exception() {
    //setup
    String mockedMethodName = 'getOneAccount';
    Account mockAccountOne = new Account(Name = 'Mock Account One');

    String mockExceptionMessage = 'Mock exception';
    AuraHandledException mockException = new AuraHandledException(mockExceptionMessage);
    mockException.setMessage(mockExceptionMessage);

    mockService.when(mockedMethodName).thenThrowUntil(2, mockException).thenReturn(mockAccountOne);

    //test
    Test.startTest();

    try {
      Account accountDetail = sut.getAccountDetail();
      Assert.fail('Expected exception to be thrown');
    } catch (AuraHandledException ex) {
      Assert.areEqual(mockExceptionMessage, ex.getMessage());
    }

    try {
      Account accountDetail = sut.getAccountDetail();
      Assert.fail('Expected exception to be thrown');
    } catch (AuraHandledException ex) {
      Assert.areEqual(mockExceptionMessage, ex.getMessage());
    }

    Account accountDetail = sut.getAccountDetail();
    Assert.areEqual(mockAccountOne.Name, accountDetail.Name);

    //should return mockAccountTwo for all subsequent calls
    for (Integer i = 0; i < 100; i++) {
      accountDetail = sut.getAccountDetail();
    }
    Assert.areEqual(mockAccountOne.Name, accountDetail.Name);
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).wasCalled(103);
  }

  @IsTest
  public static void it_should_call_overloaded_methods_multiple_return_values() {
    //setup
    String mockedMethodName = 'getMatchingAccounts';
    Account acctByIdOne = new Account(Name = 'Account with matching Id One');
    Account acctByIdTwo = new Account(Name = 'Account with matching Id Two');
    Account acctByNameOne = new Account(Name = 'Account with matching name');

    mockService.when(mockedMethodName)
      .withParamTypes(new List<Type>{ Id.class })
      .thenReturnUntil(2, new List<Account>{ acctByIdOne })
      .thenReturn(new List<Account>{ acctByIdTwo });
    mockService.when(mockedMethodName).withParamTypes(new List<Type>{ String.class }).thenReturn(new List<Account>{ acctByNameOne });

    //test
    Test.startTest();
    Id mockAccountId = '001000000000001';
    List<Account> acctsWithMatchingId = sut.getMatchingAccounts(mockAccountId);
    Assert.areEqual(acctByIdOne.Name, acctsWithMatchingId[0].Name);

    acctsWithMatchingId = sut.getMatchingAccounts(mockAccountId);
    Assert.areEqual(acctByIdOne.Name, acctsWithMatchingId[0].Name);

    acctsWithMatchingId = sut.getMatchingAccounts(mockAccountId);
    Assert.areEqual(acctByIdTwo.Name, acctsWithMatchingId[0].Name);

    for (Integer i = 0; i < 100; i++) {
      acctsWithMatchingId = sut.getMatchingAccounts(mockAccountId);
    }

    List<Account> acctsWithMatchingName = sut.getMatchingAccounts('Account with matching name');
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).withParamTypes(new List<Type>{ Id.class }).wasCalled(103);
    mockService.assertThat().method(mockedMethodName).withParamTypes(new List<Type>{ String.class }).wasCalled(1);

    Id accountIdParam = (Id) mockService.forMethod(mockedMethodName).withParamTypes(new List<Type>{ Id.class }).andInvocationNumber(50).getValueOf('accountId');
    String acctNameParam = (String) mockService.forMethod(mockedMethodName)
      .withParamTypes(new List<Type>{ String.class })
      .andInvocationNumber(0)
      .getValueOf('accountName');

    Assert.areEqual(mockAccountId, accountIdParam);
    Assert.areEqual('Account with matching name', acctNameParam);
    Assert.areEqual(acctByIdTwo.Name, acctsWithMatchingId[0].Name);
    Assert.areEqual(acctByNameOne.Name, acctsWithMatchingName[0].Name);
  }

  @IsTest
  public static void dummy_test_for_db_service() {
    AccountDBService dbSvc = new AccountDBService();
    Account a = new Account(Name = 'Acme');
    dbSvc.doInsert(a);
    dbSvc.getOneAccount();
    dbSvc.getMatchingAccounts(Id.valueOf('001000000000001'));
    dbSvc.getMatchingAccounts('Acme');
  }

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

  public class DMLMutator implements UniversalMocker.Mutator {
    // Ideally, 'fakeCounter' should be a static variable and 'getFakeId' should be a static method in another top-level class.
    private Integer fakeIdCounter = 1;
    public String getFakeId(Schema.SObjectType objType) {
      String result = String.valueOf(this.fakeIdCounter++);
      return objType.getDescribe().getKeyPrefix() + '0'.repeat(12 - result.length()) + result;
    }

    public void mutate(Object stubbedObject, String stubbedMethodName, List<Type> listOfParamTypes, List<Object> listOfArgs) {
      Account record = (Account) listOfArgs[0];
      record.Id = this.getFakeId(Account.SObjectType);
    }
  }
}
