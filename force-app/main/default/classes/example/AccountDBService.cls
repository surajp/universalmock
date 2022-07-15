public with sharing class AccountDBService {
  public Account getOneAccount() {
    return [SELECT Name FROM Account LIMIT 1];
  }

  public Account[] getMatchingAccounts(Id accountId) {
    return [SELECT Name FROM Account WHERE Id = :accountId];
  }

  public Account[] getMatchingAccounts(String accountName) {
    return [SELECT Name FROM Account WHERE Name = :accountName];
  }

  public Database.SaveResult doInsert(Account acct) {
    return Database.insert(acct);
  }
}
