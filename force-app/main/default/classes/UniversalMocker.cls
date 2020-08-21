/************************************************************

*** Copyright (c) Vertex Computer Systems Inc. All rights reserved.

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

  private boolean startStubbing = false;
  private boolean isInAssertMode = false;
  private boolean getArgumentMode = false;

  private String currentMethodName;
  private String currentParamTypesString;
  private Integer expectedCallCount;
  private Integer forInvocationNumber;
  private String currentArgumentName;

  private UniversalMocker(Type mockedClass) {
    this.mockedClass = mockedClass;
  }

  public static UniversalMocker mock(Type mockedClass) {
    return new UniversalMocker(mockedClass);
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
    return retVal;
  }

  private String getKey(String className, String methodName) {
    return className + '||' + methodName;
  }

  private String getKey(String className, String methodName, List<Type> paramTypes) {
    return className + '||' + methodName + '||' + this.getParamTypesString(paramTypes);
  }

  private String getParamTypesString(List<Type> paramTypes) {
    String[] classNames = new List<String>{};
    for (Type paramType : paramTypes) {
      classNames.add(paramType.getName());
    }
    return String.join(classNames, '-');
  }

  public void setMock(String stubbedMethodName, Object returnValue) {
    String key = getKey(this.mockedClass.getName(), stubbedMethodName);
    mocksMap.put(key, returnValue);
    callCountsMap.put(key, 0);
  }

  public UniversalMocker when(String stubbedMethodName) {
    this.startStubbing = true;
    this.currentMethodName = stubbedMethodName;
    return this;
  }

  public UniversalMocker withParamTypes(List<Type> paramTypes) {
    if (!this.startStubbing && !this.isInAssertMode) {
      throw new InvalidOperationException('Invalid order of calling the api. Must specify method name to mock/assert first');
    }
    this.currentParamTypesString = this.getParamTypesString(paramTypes);
    return this;
  }

  public UniversalMocker thenReturn(Object returnObject) {
    if (!this.startStubbing) {
      throw new InvalidOperationException('Invalid order of operations');
    }
    this.mocksMap.put(getCurrentKey(), returnObject);
    this.callCountsMap.put(getCurrentKey(), 0);
    this.startStubbing = false;
    this.currentMethodName = '';
    return this;
  }

  public Object handleMethodCall(
    Object stubbedObject,
    String stubbedMethodName,
    Type returnType,
    List<Type> listOfParamTypes,
    List<String> listOfParamNames,
    List<Object> listOfArgs
  ) {
    String mockedClass = this.getClassNameFromStubbedObjectName(stubbedObject);
    String currentKey = getKey(mockedClass, stubbedMethodName);
    String keyWithParamTypes = getKey(mockedClass, stubbedMethodName, listOfParamTypes);

    boolean useParamTypes = callCountsMap.containsKey(keyWithParamTypes);
    String keyInUse = useParamTypes ? keyWithParamTypes : currentKey;
    Integer count = callCountsMap.containsKey(keyInUse) ? callCountsMap.get(keyInUse) : 0;

    Map<String, Object> currentArgsMap = new Map<String, Object>();

    if (!argumentsMap.containsKey(keyInUse)) {
      argumentsMap.put(keyInUse, new List<Map<String, Object>>{ currentArgsMap });
    } else {
      argumentsMap.get(keyInUse).add(currentArgsMap);
    }

    for (Integer i = 0; i < listOfParamNames.size(); i++) {
      currentArgsMap.put(listOfParamNames[i], listOfArgs[i]);
    }
    callCountsMap.put(keyInUse, count + 1);
    Object returnValue = mocksMap.get(keyInUse);
    if (returnValue instanceof Exception) {
      throw (Exception) returnValue;
    }
    return returnValue;
  }

  public UniversalMocker assertThat() {
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

  public void times() {
    String currentKey = getCurrentKey();
    Integer actualCallCount = this.callCountsMap.get(currentKey);
    String methodName = this.currentMethodName;
    this.currentMethodName = '';
    this.isInAssertMode = false;
    system.assertEquals(this.expectedCallCount, actualCallCount, 'Expected call count for method ' + methodName + ' does not match the actual count');
  }

  public UniversalMocker forMethod(String stubbedMethodName) {
    this.getArgumentMode = true;
    this.currentMethodName = stubbedMethodName;
    return this;
  }

  public UniversalMocker andInvocationNumber(Integer invocation) {
    if (!this.getArgumentMode) {
      throw new InvalidOperationException('Method called without calling forMethod first');
    }
    this.forInvocationNumber = invocation;
    return this;
  }

  public UniversalMocker getArgument(String paramName) {
    if (!this.getArgumentMode) {
      throw new InvalidOperationException('Method called without calling forMethod first');
    }
    this.currentArgumentName = paramName;
    return this;
  }

  public Object value() {
    if (!this.getArgumentMode) {
      throw new InvalidOperationException('Method called without calling forMethod first');
    }
    String theKey = this.getCurrentKey();
    Object returnValue = argumentsMap.get(theKey).get(this.forInvocationNumber).get(this.currentArgumentName);
    this.currentMethodName = null;
    this.currentParamTypesString = null;
    this.forInvocationNumber = -1;
    this.currentArgumentName = null;
    this.getArgumentMode = false;
    return returnValue;
  }

  public class InvalidOperationException extends Exception {
  }
}
