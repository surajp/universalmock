@isTest
public with sharing class AccountDomainTest {
  @isTest
  public static void it_should_return_one_account() {
    Account mockAccount = new Account(Name = 'Mock Account');
    UniversalMocker mock = UniversalMocker.mock(AccountDBService.class);
    mock.when('getOneAccount').thenReturn(mockAccount);

    AccountDBService mockService = (AccountDBService) Test.createStub(AccountDBService.class, mock);
    AccountDomain acctDomainInstance = new AccountDomain(mockService);
    Account accountDetail = acctDomainInstance.getAccountDetail();

    system.assertEquals(mockAccount.Name, accountDetail.Name);
    mock.assertThat().method('getOneAccount').wasCalled(1).times();
  }

  @isTest
  public static void it_should_create_a_public_account() {
    UniversalMocker mock = UniversalMocker.mock(AccountDBService.class);
    AccountDBService mockService = (AccountDBService) Test.createStub(AccountDBService.class, mock);
    AccountDomain acctDomainInstance = new AccountDomain(mockService);
    acctDomainInstance.createPublicAccount('Mock Account');

    Account newAccount = (Account) mock.forMethod('doInsert').andInvocationNumber(0).getArgument('acct').value();

    system.assertEquals('Mock Account', newAccount.Name);
    system.assertEquals('Public', newAccount.Ownership);
  }
}
