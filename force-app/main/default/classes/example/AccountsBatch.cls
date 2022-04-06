public class AccountsBatch implements Database.Batchable<Integer> {
  AccountDomain acctDomain = null;
  public AccountsBatch(AccountDomain acctDomain) {
    this.acctDomain = acctDomain;
  }

  public Iterable<Integer> start(Database.BatchableContext bc) {
    return new List<Integer>{ 1 };
  }

  public void execute(Database.BatchableContext bc, List<Integer> scope) {
    acctDomain.getAccountDetail(); //calls AcctDBservice.getOneAccount
  }

  public void finish(Database.BatchableContext bc) {
  }
}
