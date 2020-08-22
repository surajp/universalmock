@isTest
public with sharing class AccountDomainTest {
  @isTest
  public static void it_should_return_one_account() {
    String mockedMethodName = 'getOneAccount';
    Account mockAccount = new Account(Name = 'Mock Account');
    UniversalMocker mock = UniversalMocker.mock(AccountDBService.class);
    mock.when(mockedMethodName).thenReturn(mockAccount);

    AccountDBService mockService = (AccountDBService) mock.createStub();
    AccountDomain acctDomainInstance = new AccountDomain(mockService);
    Account accountDetail = acctDomainInstance.getAccountDetail();

    system.assertEquals(mockAccount.Name, accountDetail.Name);
    mock.assertThat().method(mockedMethodName).wasCalled(1).timesExactly();
  }

  @isTest
  public static void it_should_create_a_public_account() {
    String mockedMethodName = 'doInsert';
    UniversalMocker mock = UniversalMocker.mock(AccountDBService.class);
    AccountDBService mockService = (AccountDBService) mock.createStub();
    AccountDomain acctDomainInstance = new AccountDomain(mockService);
    acctDomainInstance.createPublicAccount('Mock Account');

    Account newAccount = (Account) mock.forMethod(mockedMethodName).andInvocationNumber(0).getValueOf('acct');

    system.assertEquals('Mock Account', newAccount.Name);
    system.assertEquals('Public', newAccount.Ownership);
  }
}
