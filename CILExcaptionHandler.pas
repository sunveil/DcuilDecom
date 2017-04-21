unit CILExcaptionHandler;

interface

uses
  CILInstructions;

type

  TFlagsEHClause = (
    ehException,
    ehFilter,
    ehFinally,
    ehFault
  );

  TExceptionHandlerType = (
    eCatch = 0,
		eFilter = 1,
		eFinally = 2,
		eFault = 4
  );

type
  TExceptionHandler = record
    Flags : Integer;
 		TryStart : Integer;
		TryLength : Integer;
		FilterStart : Integer;
		HandlerStart : Integer;
		HandlerLength : Integer;
    HandlerType : TExceptionHandlerType;
    FilterOffset : Integer;
  end;

implementation

end.
