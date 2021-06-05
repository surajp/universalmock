@isTest
public with sharing class AccountDomainTest {
  private static final UniversalMocker mockService;
  private static final AccountDBService mockServiceStub;
  private static final AccountDomain sut; // system under test

  static {
    mockService = UniversalMocker.mock(AccountDBService.class);
    mockServiceStub = (AccountDBService) mockService.createStub();
    sut = new AccountDomain(mockServiceStub);
  }

  @isTest
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

  @isTest
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

  @isTest
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

  @isTest
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

  @isTest
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

  @isTest
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

  @isTest
  public static void dummy_test_for_db_service() {
    AccountDBService dbSvc = new AccountDBService();
    Account a = new Account(Name = 'Acme');
    dbSvc.doInsert(a);
    dbSvc.getOneAccount();
    dbSvc.getMatchingAccounts(Id.valueOf('001000000000001'));
    dbSvc.getMatchingAccounts('Acme');
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
