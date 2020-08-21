public with sharing class AccountDBService {
  public Account getOneAccount() {
    return [SELECT Name FROM Account LIMIT 1];
  }

  public void doInsert(Account acct) {
    insert acct;
  }
}
