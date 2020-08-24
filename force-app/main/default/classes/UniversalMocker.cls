/************************************************************

*** @author: Suraj Pillai
*** @group: Test Class
*** @date: 01/2020
*** @description: A universal class for mocking in tests. Contains a method for setting the return value for any method. Another method returns the number of times a method was called

*/
@isTest
public with sharing class UniversalMocker implements System.StubProvider {
  private Map<String, List<Map<String, Object>>> argumentsMap = new Map<String, List<Map<String, Object>>>();
  private Type mockedClass;
  private Map<String, Object> mocksMap = new Map<String, Object>();
  private Map<String, Integer> callCountsMap = new Map<String, Integer>();

  private boolean isInSetupMode = false;
  private boolean isInAssertMode = false;
  private boolean isInGetArgumentMode = false;

  private String currentMethodName;
  private String currentParamTypesString;
  private Integer expectedCallCount;
  private Integer forInvocationNumber = 0;
  private String currentArgumentName;

  private String INVALID_STATE_ERROR_MSG = 'The mock object state is invalid for this operation. Please refer to the docs';

  private enum AssertType {
    LESS_OR_EQUAL,
    MORE_OR_EQUAL,
    EQUAL
  }

  private UniversalMocker(Type mockedClass) {
    this.mockedClass = mockedClass;
  }

  public static UniversalMocker mock(Type mockedClass) {
    return new UniversalMocker(mockedClass);
  }

  public Object createStub() {
    return Test.createStub(this.mockedClass, this);
  }

  private String getClassNameFromStubbedObjectName(Object stubbedObject) {
    return String.valueOf(stubbedObject).split(':')[0].split('__')[0];
  }

  private String getCurrentKey() {
    String className = this.mockedClass.getName();
    String retVal = className + '||' + this.currentMethodName;
    if (this.currentParamTypesString != null) {
      retVal += '||' + this.currentParamTypesString;
    }
    return retVal.toLowerCase();
  }

  private String getKey(String className, String methodName) {
    return (className + '||' + methodName).toLowerCase();
  }

  private String getKey(String className, String methodName, List<Type> paramTypes) {
    return (className + '||' + methodName + '||' + this.getParamTypesString(paramTypes)).toLowerCase();
  }

  private String getParamTypesString(List<Type> paramTypes) {
    String[] classNames = new List<String>{};
    for (Type paramType : paramTypes) {
      classNames.add(paramType.getName());
    }
    return String.join(classNames, '-');
  }

  private void resetCurrentKeys() {
    this.currentParamTypesString = null;
    this.currentMethodName = null;
    this.currentArgumentName = null;
    this.isInAssertMode = false;
    this.isInSetupMode = false;
    this.isInGetArgumentMode = false;
    this.forInvocationNumber = 0;
  }

  private boolean isAnyModeActive() {
    return this.isInSetupMode || this.isInAssertMode || this.isInGetArgumentMode;
  }

  public void setMock(String stubbedMethodName, Object returnValue) {
    String key = getKey(this.mockedClass.getName(), stubbedMethodName);
    mocksMap.put(key, returnValue);
    callCountsMap.put(key, 0);
  }

  public UniversalMocker when(String stubbedMethodName) {
    if (this.isAnyModeActive()) {
      throw new InvalidOperationException(INVALID_STATE_ERROR_MSG);
    }
    this.isInSetupMode = true;
    this.currentMethodName = stubbedMethodName;
    return this;
  }

  public UniversalMocker withParamTypes(List<Type> paramTypes) {
    if (!this.isInSetupMode && !this.isInAssertMode) {
      throw new InvalidOperationException('Invalid order of calling the api. Must specify method name to mock/assert first');
    }
    this.currentParamTypesString = this.getParamTypesString(paramTypes);
    return this;
  }

  public UniversalMocker thenReturn(Object returnObject) {
    if (!this.isInSetupMode) {
      throw new InvalidOperationException('Invalid order of operations');
    }
    this.mocksMap.put(getCurrentKey(), returnObject);
    this.callCountsMap.put(getCurrentKey(), 0);
    this.resetCurrentKeys();
    return this;
  }

  private String determineKeyToUseForCurrentStubbedMethod(Object stubbedObject, String stubbedMethodName, List<Type> listOfParamTypes) {
    String mockedClass = this.getClassNameFromStubbedObjectName(stubbedObject);
    String keyWithoutParamTypes = getKey(mockedClass, stubbedMethodName);
    String keyWithParamTypes = getKey(mockedClass, stubbedMethodName, listOfParamTypes);
    return callCountsMap.containsKey(keyWithParamTypes) ? keyWithParamTypes : keyWithoutParamTypes;
  }

  private void incrementCallCount(String key) {
    Integer count = callCountsMap.containsKey(key) ? callCountsMap.get(key) : 0;
    callCountsMap.put(key, count + 1);
  }

  private void saveArguments(List<String> listOfParamNames, List<Object> listOfArgs, String key) {
    Map<String, Object> currentArgsMap = new Map<String, Object>();
    if (!argumentsMap.containsKey(key)) {
      argumentsMap.put(key, new List<Map<String, Object>>{ currentArgsMap });
    } else {
      argumentsMap.get(key).add(currentArgsMap);
    }

    for (Integer i = 0; i < listOfParamNames.size(); i++) {
      currentArgsMap.put(listOfParamNames[i], listOfArgs[i]);
    }
  }

  public Object handleMethodCall(
    Object stubbedObject,
    String stubbedMethodName,
    Type returnType,
    List<Type> listOfParamTypes,
    List<String> listOfParamNames,
    List<Object> listOfArgs
  ) {
    String keyInUse = this.determineKeyToUseForCurrentStubbedMethod(stubbedObject, stubbedMethodName, listOfParamTypes);
    this.incrementCallCount(keyInUse);
    this.saveArguments(listOfParamNames, listOfArgs, keyInUse);

    Object returnValue = mocksMap.get(keyInUse);
    if (returnValue instanceof Exception) {
      throw (Exception) returnValue;
    }
    return returnValue;
  }

  public UniversalMocker assertThat() {
    if (this.isAnyModeActive()) {
      throw new InvalidOperationException(INVALID_STATE_ERROR_MSG);
    }
    this.isInAssertMode = true;
    return this;
  }

  public UniversalMocker method(String methodName) {
    if (!this.isInAssertMode) {
      throw new InvalidOperationException('Method called without calling assertThat first');
    }
    this.currentMethodName = methodName;
    return this;
  }

  public UniversalMocker wasCalled(Integer expectedCallCount) {
    if (!this.isInAssertMode) {
      throw new InvalidOperationException('Method called without calling assertThat first');
    }
    this.expectedCallCount = expectedCallCount;
    return this;
  }

  private void assertCallCount(AssertType asserTypeValue) {
    String currentKey = getCurrentKey();
    Integer actualCallCount = this.callCountsMap.get(currentKey);
    String methodName = this.currentMethodName;
    this.resetCurrentKeys();
    switch on asserTypeValue {
      when LESS_OR_EQUAL {
        system.assert(
          this.expectedCallCount >= actualCallCount,
          'Expected call count for method ' +
          methodName +
          ' is not more than or equal to the actual count'
        );
      }
      when MORE_OR_EQUAL {
        system.assert(
          this.expectedCallCount <= actualCallCount,
          'Expected call count for method ' +
          methodName +
          ' is not more than or equal to the actual count'
        );
      }
      when else {
        system.assertEquals(this.expectedCallCount, actualCallCount, 'Expected call count for method ' + methodName + ' is not equal to the actual count');
      }
    }
  }

  public void timesOrMore() {
    this.assertCallCount(AssertType.MORE_OR_EQUAL);
  }

  public void timesOrLess() {
    this.assertCallCount(AssertType.LESS_OR_EQUAL);
  }

  public void timesExactly() {
    this.assertCallCount(AssertType.EQUAL);
  }

  public UniversalMocker forMethod(String stubbedMethodName) {
    if (this.isAnyModeActive()) {
      throw new InvalidOperationException('The object state is invalid for this operation. Please refer to the docs');
    }
    this.isInGetArgumentMode = true;
    this.currentMethodName = stubbedMethodName;
    return this;
  }

  public UniversalMocker andInvocationNumber(Integer invocation) {
    if (!this.isInGetArgumentMode) {
      throw new InvalidOperationException('Method called without calling \'forMethod\' first');
    }
    this.forInvocationNumber = invocation;
    return this;
  }

  public Object getValueOf(String paramName) {
    if (!this.isInGetArgumentMode) {
      throw new InvalidArgumentException('Method called without calling \'forMethod\' first');
    }
    String theKey = this.getCurrentKey();
    Map<String, Object> paramsMap = argumentsMap.get(theKey).get(this.forInvocationNumber);
    if (!paramsMap.containsKey(paramName)) {
      throw new InvalidOperationException(
        String.format('Param name \'${0}\' not found for the method \'${1}\'', new List<String>{ paramName, this.currentMethodName })
      );
    }
    Object returnValue = paramsMap.get(paramName);
    this.resetCurrentKeys();
    return returnValue;
  }

  public Object getArgumentsMap() {
    if (!this.isInGetArgumentMode) {
      throw new InvalidOperationException('Method called without calling \'forMethod\' first');
    }
    String theKey = this.getCurrentKey();
    Map<String, Object> returnValue = argumentsMap.get(theKey).get(this.forInvocationNumber);
    this.resetCurrentKeys();
    return returnValue;
  }

  public class InvalidOperationException extends Exception {
  }

  public class InvalidArgumentException extends Exception {
  }
}
