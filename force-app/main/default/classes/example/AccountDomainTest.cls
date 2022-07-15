@IsTest
public with sharing class AccountDomainTest {
  private static final String ACCOUNT_ID_IS_NULL_AFTER_INSERT = 'Account Id is null after insert';
  private static final String ACCOUNT_WITH_MATCHING_NAME = 'Account with matching name';
  private static final String ACCT = 'acct';
  private static final String ACME = 'Acme';
  private static final String DO_INSERT = 'doInsert';
  private static final String GET_MATCHING_ACCOUNTS = 'getMatchingAccounts';
  private static final String GET_ONE_ACCOUNT = 'getOneAccount';
  private static final String MOCK_ACCOUNT = 'Mock Account';
  private static final String MOCK_EXCEPTION = 'Mock exception';
  private static final String MOCKED_ACCOUNT_ID = '001000000000001';
  private static final String MOCKED_DUMMY_METHOD = 'mockedDummyMethod';
  private static final String MOCKED_EXCEPTION_WAS_NOT_THROWN = 'Mocked exception was not thrown';

  private static final UniversalMocker mockService;
  private static final AccountDBService mockServiceStub;
  private static final AccountDomain sut; // system under test

  static {
    mockService = UniversalMocker.mock(AccountDBService.class);
    mockServiceStub = (AccountDBService) mockService.createStub();
    sut = new AccountDomain(mockServiceStub);
  }

  @IsTest
  public static void it_should_return_one_account() {
    //setup
    String mockedMethodName = GET_ONE_ACCOUNT;
    Account mockAccount = new Account(Name = MOCK_ACCOUNT);

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
    String mockedMethodName = DO_INSERT;

    //test
    Test.startTest();
    sut.createPublicAccount(MOCK_ACCOUNT);
    Test.stopTest();

    //verify
    Account newAccount = (Account) mockService.forMethod(mockedMethodName).andInvocationNumber(0).getValueOf(ACCT);
    system.assertEquals(MOCK_ACCOUNT, newAccount.Name);
    system.assertEquals(AccountDomain.PUBLIC_STRING, newAccount.Ownership);
  }

  @IsTest
  public static void it_should_verify_call_counts_correctly() {
    //setup
    String mockedMethodName = GET_ONE_ACCOUNT;
    Account mockAccount = new Account(Name = MOCK_ACCOUNT);

    mockService.when(mockedMethodName).thenReturn(mockAccount);
    mockService.when(MOCKED_DUMMY_METHOD).thenReturn(null);

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
    mockService.assertThat().method(MOCKED_DUMMY_METHOD).wasNeverCalled();
    mockService.assertThat().method('nonMockedDummyMethod').wasNeverCalled();
  }

  @IsTest
  public static void it_should_call_overloaded_methods_correctly() {
    //setup
    String mockedMethodName = GET_MATCHING_ACCOUNTS;
    Account acctOne = new Account(Name = 'Account with matching Id');
    Account acctTwo = new Account(Name = ACCOUNT_WITH_MATCHING_NAME);

    mockService.when(mockedMethodName).withParamTypes(new List<Type>{ Id.class }).thenReturn(new List<Account>{ acctOne });
    mockService.when(mockedMethodName).withParamTypes(new List<Type>{ String.class }).thenReturn(new List<Account>{ acctTwo });

    //test
    Test.startTest();
    Id mockAccountId = MOCKED_ACCOUNT_ID;
    List<Account> acctsWithMatchingId = sut.getMatchingAccounts(mockAccountId);
    List<Account> acctsWithMatchingName = sut.getMatchingAccounts(ACCOUNT_WITH_MATCHING_NAME);
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
    System.assertEquals(ACCOUNT_WITH_MATCHING_NAME, acctNameParam);
    System.assertEquals(acctOne.Name, acctsWithMatchingId[0].Name);
    System.assertEquals(acctTwo.Name, acctsWithMatchingName[0].Name);
  }

  @IsTest
  public static void it_should_throw_mock_exception() {
    //setup
    String mockedMethodName = DO_INSERT;
    String mockExceptionMessage = MOCK_EXCEPTION;
    AuraHandledException mockException = new AuraHandledException(mockExceptionMessage);
    /*https://salesforce.stackexchange.com/questions/122657/testing-aurahandledexceptions*/
    mockException.setMessage(mockExceptionMessage);

    mockService.when(mockedMethodName).thenThrow(mockException);

    //test
    Test.startTest();
    boolean hasException = false;
    try {
      sut.createPublicAccount(MOCK_ACCOUNT);
    } catch (AuraHandledException ex) {
      System.assertEquals(mockExceptionMessage, ex.getMessage());
      hasException = true;
    }
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).wasCalled(1);
    System.assert(hasException, MOCKED_EXCEPTION_WAS_NOT_THROWN);
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
    String mockedMethodName = DO_INSERT;
    String mockExceptionMessage = MOCK_EXCEPTION;
    UniversalMocker.Mutator dmlMutatorInstance = new DMLMutator();

    mockService.when(mockedMethodName).mutateWith(dmlMutatorInstance).thenReturnVoid();
    AccountsQueuable queueableSut = new AccountsQueuable(sut);

    //test
    Test.startTest();
    System.enqueueJob(queueableSut);
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).wasCalled(1);
    Account acct = (Account) mockService.forMethod(mockedMethodName).getValueOf(ACCT);
    System.assertNotEquals(null, acct.Id, ACCOUNT_ID_IS_NULL_AFTER_INSERT);
  }

  @IsTest
  public static void it_should_track_call_counts_with_batchables() {
    String mockedMethodName = GET_ONE_ACCOUNT;
    Account mockAccount = new Account(Name = MOCK_ACCOUNT);
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
    String mockedMethodName = DO_INSERT;
    String mockExceptionMessage = MOCK_EXCEPTION;
    UniversalMocker.Mutator dmlMutatorInstance = new DMLMutator();

    mockService.when(mockedMethodName).mutateWith(dmlMutatorInstance).thenReturnVoid();

    //test
    Test.startTest();
    boolean hasException = false;
    try {
      sut.createPublicAccount(MOCK_ACCOUNT);
    } catch (AuraHandledException ex) {
      System.assertEquals(mockExceptionMessage, ex.getMessage());
      hasException = true;
    }
    Test.stopTest();

    //verify
    mockService.assertThat().method(mockedMethodName).wasCalled(1);
    System.assert(!hasException, MOCKED_EXCEPTION_WAS_NOT_THROWN);
    Account acct = (Account) mockService.forMethod(DO_INSERT).getValueOf(ACCT);
    System.assertNotEquals(null, acct.Id, ACCOUNT_ID_IS_NULL_AFTER_INSERT);
  }

  @IsTest
  private static void create_two_accounts_should_succeed_if_both_are_successful() {
    //setup
    String mockedMethodName = DO_INSERT;
    Database.SaveResult mockedSaveResult = generateSaveResult(true);
    mockService.when(mockedMethodName).thenReturn(mockedSaveResult);
    AccountDomain.AccountDomainException myException;

    //test
    Test.startTest();
    try {
      sut.createTwoPublicAccounts(ACME);
    } catch (AccountDomain.AccountDomainException e) {
      myException = e;
    }
    Test.stopTest();

    //verify
    System.assertEquals(null, myException, 'An exception should be thrown because the Database.SaveResult is not successful');
  }

  @IsTest
  private static void create_two_accounts_should_throw_initial_exception_if_initial_is_unsuccessful() {
    //setup
    String mockedMethodName = DO_INSERT;
    Database.SaveResult mockedSaveResult = generateSaveResult(false);
    mockService.when(mockedMethodName).isCalledForTheNthTime(1).thenReturn(mockedSaveResult);
    AccountDomain.AccountDomainException myException;

    //test
    Test.startTest();
    try {
      sut.createTwoPublicAccounts(ACME);
    } catch (AccountDomain.AccountDomainException e) {
      myException = e;
    }
    Test.stopTest();

    //verify
    System.assertNotEquals(null, myException, 'An exception should be thrown because the Database.SaveResult is not successful');
    System.assertEquals(true, myException.getMessage() == AccountDomain.INITAL_UNSUCCESS_MESSAGE, 'The exception should be for the initial SaveResult');
  }

  @IsTest
  private static void create_two_accounts_should_throw_copy_exception_if_second_is_unsuccessful() {
    //setup
    String mockedMethodName = DO_INSERT;
    mockService.when(mockedMethodName).isCalledForTheNthTime(1).thenReturn(generateSaveResult(true));
    mockService.when(mockedMethodName).isCalledForTheNthTime(2).thenReturn(generateSaveResult(false));
    AccountDomain.AccountDomainException myException;

    //test
    Test.startTest();
    try {
      sut.createTwoPublicAccounts(ACME);
    } catch (AccountDomain.AccountDomainException e) {
      myException = e;
    }
    Test.stopTest();

    //verify
    System.assertNotEquals(null, myException, 'An exception should be thrown because the Database.SaveResult is not successful');
    System.assertEquals(true, myException.getMessage() == AccountDomain.SECOND_UNSUCCESS_MESSAGE, 'The exception should be for the second SaveResult');
  }

  @IsTest
  private static void setting_is_called_for_the_nth_time_for_negative_numbers_should_cause_illegal_argument() {
    //setup
    String mockedMethodName = DO_INSERT;
    IllegalArgumentException myException;

    //test
    Test.startTest();
    try {
      mockService.when(mockedMethodName).isCalledForTheNthTime(-1).thenReturn(generateSaveResult(true));
    } catch (IllegalArgumentException e) {
      myException = e;
    }
    Test.stopTest();

    //verify
    System.assertNotEquals(null, myException, 'An exception should be thrown because `isCalledForTheNthTime` is not valid for n=-1');
  }

  @IsTest
  private static void skipping_indicies_when_setting_is_called_for_the_nth_time_should_cause_invalid_operation() {
    //setup
    String mockedMethodName = DO_INSERT;
    mockService.when(mockedMethodName).isCalledForTheNthTime(1).thenReturn(generateSaveResult(true));
    mockService.when(mockedMethodName).isCalledForTheNthTime(3).thenReturn(generateSaveResult(false));
    UniversalMocker.InvalidOperationException myException;

    //test
    Test.startTest();
    try {
      sut.createTwoPublicAccounts(ACME);
    } catch (UniversalMocker.InvalidOperationException e) {
      myException = e;
    }
    Test.stopTest();

    //verify
    System.assertNotEquals(null, myException, 'An exception should be thrown because the index of 2 was skipped');
    System.assertEquals(
      String.format(UniversalMocker.MISSING_RETURN_VALUE_FOR_NTH_TIME_CALLING, new List<String>{ String.valueOf(2) }),
      myException.getMessage(),
      'The exceptions\'s message is improperly formatted'
    );
  }

  private static Database.SaveResult generateSaveResult(Boolean success) {
    return (Database.SaveResult) JSON.deserialize(JSON.serialize(new Map<String, Object>{ 'success' => success }, true), Database.SaveResult.class);
  }

  @IsTest
  public static void dummy_test_for_db_service() {
    AccountDBService dbSvc = new AccountDBService();
    Account a = new Account(Name = ACME);
    dbSvc.doInsert(a);
    dbSvc.getOneAccount();
    dbSvc.getMatchingAccounts(Id.valueOf(MOCKED_ACCOUNT_ID));
    dbSvc.getMatchingAccounts(ACME);
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
