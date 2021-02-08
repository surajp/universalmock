/************************************************************

*** @author: Suraj Pillai
*** @group: Test Class
*** @date: 01/2020
*** @description: A universal class for mocking in tests. Contains a method for setting the return value for any method. Another method returns the number of times a method was called

*/
@isTest
public with sharing class UniversalMocker implements System.StubProvider {
  private final Map<String, List<Map<String, Object>>> argumentsMap = new Map<String, List<Map<String, Object>>>();
  private final Type mockedClass;
  private final Map<String, Object> mocksMap = new Map<String, Object>();
  private final Map<String, Integer> callCountsMap = new Map<String, Integer>();

  private Boolean isInSetupMode = false;
  private Boolean isInAssertMode = false;
  private Boolean isInGetArgumentMode = false;

  private String currentMethodName;
  private String currentParamTypesString;
  private Integer expectedCallCount;
  private Integer forInvocationNumber = 0;

  private String INVALID_STATE_ERROR_MSG = 'Mocker object state is invalid for this operation. Please refer to the Readme';
  private String KEY_DELIMITER = '||';

  //Map for storing mutators
  Map<String, List<Mutator>> mutatorMap = new Map<String, List<Mutator>>();

  public enum Times {
    OR_LESS,
    OR_MORE,
    EXACTLY
  }

  public static UniversalMocker mock(Type mockedClass) {
    return new UniversalMocker(mockedClass);
  }

  public Object createStub() {
    return Test.createStub(this.mockedClass, this);
  }

  public void setMock(String stubbedMethodName, Object returnValue) {
    String key = this.getKey(this.mockedClass.getName(), stubbedMethodName);
    this.mocksMap.put(key, returnValue);
    this.callCountsMap.put(key, 0);
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
    if (!this.isAnyModeActive()) {
      throw new InvalidOperationException('Invalid order of operations. Must specify method name to mock/assert first');
    }
    this.currentParamTypesString = this.getParamTypesString(paramTypes);
    return this;
  }

  public UniversalMocker mutateWith(Mutator mutatorInstance) {
    if (!this.isInSetupMode) {
      throw new InvalidOperationException('Invalid order of operations. Must specify method name to mock/assert first');
    }
    String key = this.getCurrentKey();
    if (this.mutatorMap.containsKey(key)) {
      this.mutatorMap.get(key).add(mutatorInstance);
    } else {
      this.mutatorMap.put(key, new List<Mutator>{ mutatorInstance });
    }
    if (!this.callCountsMap.containsKey(key)) {
      this.callCountsMap.put(key, 0);
    }
    return this;
  }

  public UniversalMocker thenReturnVoid() {
    return this.thenReturn(null);
  }

  public UniversalMocker thenReturn(Object returnObject) {
    if (!this.isInSetupMode) {
      throw new InvalidOperationException('Invalid order of operations. Must specify method name to mock/assert first');
    }
    String key = this.getCurrentKey();
    this.mocksMap.put(key, returnObject);
    if (!this.callCountsMap.containsKey(key)) {
      this.callCountsMap.put(key, 0);
    }
    this.resetState();
    return this;
  }

  public UniversalMocker thenThrow(Exception exceptionToThrow) {
    return this.thenReturn(exceptionToThrow);
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
      throw new InvalidOperationException('Invalid order of operations. Method called without calling assertThat first');
    }
    this.currentMethodName = methodName;
    return this;
  }

  public void wasCalled(Integer expectedCallCount, Times assertTypeValue) {
    if (!this.isInAssertMode) {
      throw new InvalidOperationException('Invalid order of operations. Method called without calling assertThat first');
    }
    this.expectedCallCount = expectedCallCount;
    String currentKey = this.getCurrentKey();
    Integer actualCallCount = this.callCountsMap.get(currentKey);
    String methodName = this.currentMethodName;
    this.resetState();
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

  public void wasNeverCalled() {
    if (!this.isInAssertMode) {
      throw new InvalidOperationException('Invalid order of operations. Method called without calling assertThat first');
    }
    String currentKey = this.getCurrentKey();
    Integer actualCallCount = this.callCountsMap.get(currentKey);
    String methodName = this.currentMethodName;
    this.resetState();
    if (actualCallCount != null) {
      this.expectedCallCount = 0;
      system.assertEquals(this.expectedCallCount, actualCallCount, String.format('Method {0} was called 1 or more times', new List<String>{ methodName }));
    }
  }

  public UniversalMocker forMethod(String stubbedMethodName) {
    if (this.isAnyModeActive()) {
      throw new InvalidOperationException(INVALID_STATE_ERROR_MSG);
    }
    this.isInGetArgumentMode = true;
    this.currentMethodName = stubbedMethodName;
    return this;
  }

  public UniversalMocker andInvocationNumber(Integer invocation) {
    if (!this.isInGetArgumentMode) {
      throw new InvalidOperationException('Invalid order of operations. Method called without calling \'forMethod\' first');
    }
    this.forInvocationNumber = invocation;
    return this;
  }

  public Object getValueOf(String paramName) {
    if (!this.isInGetArgumentMode) {
      throw new InvalidOperationException('Invalid order of operations. Method called without calling \'forMethod\' first');
    }
    String theKey = this.getCurrentKey();
    Map<String, Object> paramsMap = argumentsMap.get(theKey).get(this.forInvocationNumber);
    if (!paramsMap.containsKey(paramName.toLowerCase())) {
      throw new IllegalArgumentException(String.format('Param name {0} not found for the method {1}', new List<Object>{ paramName, this.currentMethodName }));
    }
    Object returnValue = paramsMap.get(paramName.toLowerCase());
    this.resetState();
    return returnValue;
  }

  public Object getArgumentsMap() {
    if (!this.isInGetArgumentMode) {
      throw new InvalidOperationException('Invalid order of operations. Method called without calling \'forMethod\' first');
    }
    String theKey = this.getCurrentKey();
    Map<String, Object> returnValue = this.argumentsMap.get(theKey).get(this.forInvocationNumber);
    this.resetState();
    return returnValue;
  }

  public class InvalidOperationException extends Exception {
  }

  public Object handleMethodCall(
    Object stubbedObject,
    String stubbedMethodName,
    Type returnType, //currently unused
    List<Type> listOfParamTypes,
    List<String> listOfParamNames,
    List<Object> listOfArgs
  ) {
    if (this.isAnyModeActive()) {
      throw new InvalidOperationException(INVALID_STATE_ERROR_MSG);
    }
    String keyInUse = this.determineKeyToUseForCurrentStubbedMethod(stubbedObject, stubbedMethodName, listOfParamTypes);
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
    return returnValue;
  }

  public interface Mutator {
    void mutate(Object stubbedObject, String stubbedMethodName, List<Type> listOfParamTypes, List<Object> listOfArgs);
  }

  private UniversalMocker(Type mockedClass) {
    this.mockedClass = mockedClass;
  }

  private String getClassNameFromStubbedObjectName(Object stubbedObject) {
    String result = 'DateTime';
    try {
      DateTime typeCheck = (DateTime) stubbedObject;
    } catch (System.TypeException te) {
      String message = te.getMessage().substringAfter('Invalid conversion from runtime type ');
      result = message.substringBefore(' to Datetime');
    }
    return result;
  }

  private String getCurrentKey() {
    String className = this.mockedClass.getName();
    String retVal = className + KEY_DELIMITER + this.currentMethodName;
    if (this.currentParamTypesString != null) {
      retVal += KEY_DELIMITER + this.currentParamTypesString;
    }
    return retVal.toLowerCase();
  }

  private String getKey(String className, String methodName) {
    return (className + KEY_DELIMITER + methodName).toLowerCase();
  }

  private String getKey(String className, String methodName, List<Type> paramTypes) {
    return (className + KEY_DELIMITER + methodName + KEY_DELIMITER + this.getParamTypesString(paramTypes)).toLowerCase();
  }

  private String getParamTypesString(List<Type> paramTypes) {
    String[] classNames = new List<String>{};
    for (Type paramType : paramTypes) {
      classNames.add(paramType.getName());
    }
    return String.join(classNames, '-');
  }

  private void resetState() {
    this.currentParamTypesString = null;
    this.currentMethodName = null;
    this.isInAssertMode = false;
    this.isInSetupMode = false;
    this.isInGetArgumentMode = false;
    this.forInvocationNumber = 0;
  }

  private boolean isAnyModeActive() {
    return this.isInSetupMode || this.isInAssertMode || this.isInGetArgumentMode;
  }

  private String determineKeyToUseForCurrentStubbedMethod(Object stubbedObject, String stubbedMethodName, List<Type> listOfParamTypes) {
    String mockedClass = this.getClassNameFromStubbedObjectName(stubbedObject);
    String keyWithoutParamTypes = this.getKey(mockedClass, stubbedMethodName);
    String keyWithParamTypes = this.getKey(mockedClass, stubbedMethodName, listOfParamTypes);
    return this.callCountsMap.containsKey(keyWithParamTypes) ? keyWithParamTypes : keyWithoutParamTypes;
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
}
