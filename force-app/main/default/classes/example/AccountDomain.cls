public with sharing class AccountDomain {
  public static final String INITAL_UNSUCCESS_MESSAGE = 'Initial Result Unsuccessful';
  public static final String PUBLIC_STRING = 'public';
  public static final String SECOND_UNSUCCESS_MESSAGE = 'Second Result Unsuccessful';

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
    Account acct = new Account(Name = acctName, Ownership = PUBLIC_STRING);
    this.acctService.doInsert(acct);
  }

  public void createTwoPublicAccounts(String acctName) {
    Account acct = new Account(Name = acctName, Ownership = PUBLIC_STRING);
    Database.SaveResult initialResult = this.acctService.doInsert(acct);
    if (initialResult.isSuccess() == false) {
      throw new AccountDomainException(INITAL_UNSUCCESS_MESSAGE);
    }

    Account acct2 = new Account(Name = 'Copy of ' + acctName, Ownership = PUBLIC_STRING);
    Database.SaveResult copyResult = this.acctService.doInsert(acct2);
    if (copyResult.isSuccess() == false) {
      throw new AccountDomainException(SECOND_UNSUCCESS_MESSAGE);
    }
  }

  public Account[] getMatchingAccounts(String attribute) {
    if (attribute instanceof Id) {
      return this.acctService.getMatchingAccounts(Id.valueOf(attribute));
    } else {
      return this.acctService.getMatchingAccounts(attribute);
    }
  }

  public class AccountDomainException extends Exception {
  }
}
