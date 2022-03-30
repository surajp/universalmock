public with sharing class AccountsQueuable implements Queueable {
  AccountDomain acctDomainInstance = null;
  public AccountsQueuable(AccountDomain acctDomain) {
    this.acctDomainInstance = acctDomain;
  }

  public void execute(System.QueueableContext qc) {
    this.acctDomainInstance.createPublicAccount('Test Account');
  }
}
