public with sharing class AccountDomain {
  AccountDBService acctService = null;

  public AccountDomain(AccountDBService svc) {
    this.acctService = svc;
  }

  public AccountDomain() {
    this.acctService = new AccountDBService();
  }

  public Account getAccountDetail() {
    return this.acctService.getOneAccount();
  }

  public void createPublicAccount(String acctName) {
    Account acct = new Account(Name = acctName, Ownership = 'Public');
    this.acctService.doInsert(acct);
  }

  public Account[] getMachingAccounts(String attribute) {
    if (attribute instanceof Id) {
      return this.acctService.getMatchingAccounts(Id.valueOf(attribute));
    } else {
      return this.acctService.getMatchingAccounts(attribute);
    }
  }
}
