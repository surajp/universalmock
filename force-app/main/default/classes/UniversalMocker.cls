/************************************************************

*** @author: Suraj Pillai
*** @group: Test Class
*** @date: 01/2020
*** @description: A universal class for mocking in tests. Contains a method for setting the return value for any method. Another method returns the number of times a method was called. https://github.com/surajp/universalmock

*/
@isTest
public with sharing class UniversalMocker implements System.StubProvider {
  // Map of methodName+paramTypes -> map of (paramname,value) for each invocation
  private final Map<String, List<Map<String, Object>>> argumentsMap = new Map<String, List<Map<String, Object>>>();
  private final Type mockedClass;
  private final Map<String, Object> mocksMap = new Map<String, Object>();
  private final Map<String, Integer> callCountsMap = new Map<String, Integer>();

  @TestVisible
  private static final Map<String, UniversalMocker> uMockInstances = new Map<String, UniversalMocker>();

  //even though the 'guid' we are generating is a long (using Crypto.getRandomLong), we keep this a string, to make it easier if we need to switch to an actual guid in the future, and it isn't really costing us anything
  private String guid;

  private String currentMethodName;
  private String currentParamTypesString;
  private Integer expectedCallCount;
  private Integer forInvocationNumber = 0;

  private String KEY_DELIMITER = '||';

  //Map for storing mutators
  Map<String, List<Mutator>> mutatorMap = new Map<String, List<Mutator>>();

  // Inner class instances
  private SetupMode_Entry setupAInstance;
  private AssertMode_Entry assertAInstance;
  private AssertMode_Midway assertBInstance;
  private GetParamsMode_Entry getParamsAInstance;

  private enum Modes {
    SETUP,
    ASSERT,
    GETPARAMS
  }

  /* Begin Public Methods */

  public enum Times {
    OR_LESS,
    OR_MORE,
    EXACTLY
  }

  public static UniversalMocker mock(Type mockedClass) {
    UniversalMocker uMock = new UniversalMocker(mockedClass);
    uMockInstances.put(uMock.guid, uMock);
    return uMock;
  }

  public Object createStub() {
    return Test.createStub(this.mockedClass, this);
  }

  public class SetupMode_Entry extends SetupMode_Midway {
    private SetupMode_Entry(UniversalMocker parent) {
      super(parent);
    }
    public SetupMode_Midway withParamTypes(List<Type> paramTypes) {
      this.parent.withParamTypes(paramTypes);
      return (SetupMode_Midway) this;
    }
  }

  public virtual class SetupMode_Midway {
    private final UniversalMocker parent;
    private SetupMode_Midway(UniversalMocker parent) {
      this.parent = parent;
    }
    public void thenReturnVoid() {
      this.parent.thenReturnVoid();
    }
    public void thenReturn(Object returnObject) {
      this.parent.thenReturn(returnObject);
    }
    public SetupMode_Midway mutateWith(Mutator mutatorInstance) {
      this.parent.mutateWith(mutatorInstance);
      return this;
    }
    public void thenThrow(Exception exceptionToThrow) {
      this.parent.thenThrow(exceptionToThrow);
    }
  }

  public class AssertMode_Entry {
    private final UniversalMocker parent;
    private AssertMode_Entry(UniversalMocker parent) {
      this.parent = parent;
    }
    public AssertMode_Midway method(String methodName) {
      parent.method(methodName);
      return parent.assertBInstance;
    }
  }

  public class AssertMode_Midway extends AssertMode_Exit {
    private AssertMode_Midway(UniversalMocker parent) {
      super(parent);
    }
    public AssertMode_Exit withParamTypes(List<Type> paramTypes) {
      parent.withParamTypes(paramTypes);
      return (AssertMode_Exit) this;
    }
  }

  public virtual class AssertMode_Exit {
    private final UniversalMocker parent;
    private AssertMode_Exit(UniversalMocker parent) {
      this.parent = parent;
    }
    public void wasCalled(Integer expectedCallCount, Times assertTypeValue) {
      parent.wasCalled(expectedCallCount, assertTypeValue);
    }
    public void wasCalled(Integer expectedCallCount) {
      parent.wasCalled(expectedCallCount);
    }
    public void wasNeverCalled() {
      parent.wasNeverCalled();
    }
  }

  public class GetParamsMode_Entry extends GetParamsMode_Midway {
    private GetParamsMode_Entry(UniversalMocker parent) {
      super(parent);
    }
    public GetParamsMode_Midway withParamTypes(List<Type> paramTypes) {
      parent.withParamTypes(paramTypes);
      return (GetParamsMode_Midway) this;
    }
  }

  public virtual class GetParamsMode_Midway extends GetParamsMode_Exit {
    private GetParamsMode_Midway(UniversalMocker parent) {
      super(parent);
    }
    public GetParamsMode_Exit andInvocationNumber(Integer invocation) {
      parent.andInvocationNumber(invocation);
      return (GetParamsMode_Exit) this;
    }
  }

  public virtual class GetParamsMode_Exit {
    private final UniversalMocker parent;
    private GetParamsMode_Exit(UniversalMocker parent) {
      this.parent = parent;
    }
    public Object getValueOf(String paramName) {
      return parent.getValueOf(paramName);
    }
    public Map<String, Object> getArgumentsMap() {
      return parent.getArgumentsMap();
    }
  }

  public SetupMode_Entry when(String stubbedMethodName) {
    this.currentMethodName = stubbedMethodName;
    return this.setupAInstance;
  }

  public Object handleMethodCall(
    Object stubbedObject,
    String stubbedMethodName,
    Type returnType, //currently unused
    List<Type> listOfParamTypes,
    List<String> listOfParamNames,
    List<Object> listOfArgs
  ) {
    String keyInUse = this.determineKeyToUseForCurrentStubbedMethod(stubbedMethodName, listOfParamTypes);
    this.incrementCallCount(keyInUse);
    this.saveArguments(listOfParamNames, listOfArgs, keyInUse);

    Object returnValue = this.mocksMap.get(keyInUse);

    if (this.mutatorMap.containsKey(keyInUse)) {
      for (Mutator m : this.mutatorMap.get(keyInUse)) {
        m.mutate(stubbedObject, stubbedMethodName, listOfParamTypes, listOfArgs);
      }
    }

    if (returnValue instanceof Exception) {
      throw (Exception) returnValue;
    }
    this.copyState(); //for async calls, we store the current object instance in a static map so the state is preserved even after leaving the async context
    return returnValue;
  }

  public AssertMode_Entry assertThat() {
    return this.assertAInstance;
  }

  public GetParamsMode_Entry forMethod(String stubbedMethodName) {
    this.currentMethodName = stubbedMethodName;
    return this.getParamsAInstance;
  }

  public class InvalidOperationException extends Exception {
  }

  public interface Mutator {
    void mutate(Object stubbedObject, String stubbedMethodName, List<Type> listOfParamTypes, List<Object> listOfArgs);
  }

  /* End Public methods */

  /* Begin Private methods */

  private void withParamTypes(List<Type> paramTypes) {
    this.currentParamTypesString = this.getParamTypesString(paramTypes);
  }

  private void mutateWith(Mutator mutatorInstance) {
    String key = this.getCurrentKey();
    if (this.mutatorMap.containsKey(key)) {
      this.mutatorMap.get(key).add(mutatorInstance);
    } else {
      this.mutatorMap.put(key, new List<Mutator>{ mutatorInstance });
    }
    if (!this.callCountsMap.containsKey(key)) {
      this.callCountsMap.put(key, 0);
    }
  }

  private void thenReturnVoid() {
    this.thenReturn(null);
  }

  private void thenReturn(Object returnObject) {
    String key = this.getCurrentKey();
    this.mocksMap.put(key, returnObject);
    if (!this.callCountsMap.containsKey(key)) {
      this.callCountsMap.put(key, 0);
    }
  }

  private void thenThrow(Exception exceptionToThrow) {
    this.thenReturn(exceptionToThrow);
  }

  private void method(String methodName) {
    this.currentMethodName = methodName;
  }

  private void wasCalled(Integer expectedCallCount) {
    wasCalled(expectedCallCount, UniversalMocker.Times.EXACTLY);
  }

  private void wasCalled(Integer expectedCallCount, Times assertTypeValue) {
    this.expectedCallCount = expectedCallCount;
    String currentKey = this.getCurrentKey();
    //Integer actualCallCount = this.callCountsMap.get(currentKey);
    Integer actualCallCount = this.getCallCountsMapInternal().get(currentKey);
    String methodName = this.currentMethodName;
    switch on assertTypeValue {
      when OR_LESS {
        system.assert(this.expectedCallCount >= actualCallCount, this.getMethodCallCountAssertMessage(methodName, 'less than or equal'));
      }
      when OR_MORE {
        system.assert(this.expectedCallCount <= actualCallCount, this.getMethodCallCountAssertMessage(methodName, 'more than or equal'));
      }
      when else {
        system.assertEquals(this.expectedCallCount, actualCallCount, this.getMethodCallCountAssertMessage(methodName, 'equal'));
      }
    }
  }

  private void wasNeverCalled() {
    String currentKey = this.getCurrentKey();
    Integer actualCallCount = this.getCallCountsMapInternal().get(currentKey);
    String methodName = this.currentMethodName;
    if (actualCallCount != null) {
      this.expectedCallCount = 0;
      system.assertEquals(this.expectedCallCount, actualCallCount, String.format('Method {0} was called 1 or more times', new List<String>{ methodName }));
    }
  }

  private void andInvocationNumber(Integer invocation) {
    this.forInvocationNumber = invocation;
  }

  private Object getValueOf(String paramName) {
    String theKey = this.getCurrentKey();
    Map<String, Object> paramsMap = this.getArgumentsMapInternal().get(theKey).get(this.forInvocationNumber);
    if (!paramsMap.containsKey(paramName.toLowerCase())) {
      throw new IllegalArgumentException(String.format('Param name {0} not found for the method {1}', new List<Object>{ paramName, this.currentMethodName }));
    }
    Object returnValue = paramsMap.get(paramName.toLowerCase());
    return returnValue;
  }

  private Map<String, Object> getArgumentsMap() {
    String theKey = this.getCurrentKey();
    Map<String, Object> returnValue = this.getArgumentsMapInternal().get(theKey).get(this.forInvocationNumber);
    return returnValue;
  }

  private String getCurrentKey() {
    String retVal = this.currentMethodName;
    if (this.currentParamTypesString != null) {
      retVal += KEY_DELIMITER + this.currentParamTypesString;
    }
    return retVal.toLowerCase();
  }

  private String getKey(String methodName, List<Type> paramTypes) {
    return (methodName + KEY_DELIMITER + this.getParamTypesString(paramTypes)).toLowerCase();
  }

  private String getParamTypesString(List<Type> paramTypes) {
    String[] classNames = new List<String>{};
    for (Type paramType : paramTypes) {
      classNames.add(paramType.getName());
    }
    return String.join(classNames, '-');
  }

  private String determineKeyToUseForCurrentStubbedMethod(String stubbedMethodName, List<Type> listOfParamTypes) {
    String keyWithParamTypes = this.getKey(stubbedMethodName, listOfParamTypes);
    return this.callCountsMap.containsKey(keyWithParamTypes) ? keyWithParamTypes : stubbedMethodName.toLowerCase();
  }

  private void incrementCallCount(String key) {
    Integer count = this.callCountsMap.containsKey(key) ? this.callCountsMap.get(key) : 0;
    this.callCountsMap.put(key, count + 1);
  }

  private void saveArguments(List<String> listOfParamNames, List<Object> listOfArgs, String key) {
    Map<String, Object> currentArgsMap = new Map<String, Object>();
    if (!this.argumentsMap.containsKey(key)) {
      this.argumentsMap.put(key, new List<Map<String, Object>>{ currentArgsMap });
    } else {
      this.argumentsMap.get(key).add(currentArgsMap);
    }

    for (Integer i = 0; i < listOfParamNames.size(); i++) {
      currentArgsMap.put(listOfParamNames[i].toLowerCase(), listOfArgs[i]);
    }
  }

  private String getMethodCallCountAssertMessage(String methodName, String comparison) {
    return String.format('Expected call count for method {0} is not {1} to the actual count', new List<String>{ methodName, comparison });
  }

  private Map<String, Integer> getCallCountsMapInternal() {
    return uMockInstances.get(this.guid).callCountsMap;
  }

  private Map<String, List<Map<String, Object>>> getArgumentsMapInternal() {
    return uMockInstances.get(this.guid).argumentsMap;
  }

  private void copyState() {
    uMockInstances.put(this.guid, this);
  }

  private UniversalMocker(Type mockedClass) {
    this.mockedClass = mockedClass;
    this.guid = this.getGUID();
    this.initInnerClassInstances();
  }

  private String getGUID() {
    String guid = Crypto.getRandomLong() + ''; // since guid generation is expensive, we "settle" for this, as it generates unique values and is performant
    return guid;
  }

  private void initInnerClassInstances() {
    this.setupAInstance = new SetupMode_Entry(this);
    this.assertAInstance = new AssertMode_Entry(this);
    this.assertBInstance = new AssertMode_Midway(this);
    this.getParamsAInstance = new GetParamsMode_Entry(this);
  }

  /* End  Private Methods */
}
