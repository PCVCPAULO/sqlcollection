// ***************************************************************************
//
// SQLCollection
//
// Copyright (c) 2020 Jo�o Ant�nio Duarte
//
// https://github.com/joaoduarte19/sqlcollection
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************

unit SQLCollection.Core;

interface

uses
  System.Classes,
  System.SysUtils,
  SQLCollection.Base;

type
  TSQLCategories = class;
  TSQLCategory = class;
  TSQLItems = class;
  TSQLItem = class;

  [ComponentPlatformsAttribute(pidAllPlatforms)]
  TSQLCollection = class(TComponent)
  private
    FItems: TSQLCategories;
    procedure SetItems(const Value: TSQLCategories);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function FindSQL(const ASQLItemName, ASQLCategoryName: string): string;
    function FindSQLItem(const ASQLItemName, ASQLCategoryName: string): TSQLItem;
    function FindSQLCategory(const ASQLCategoryName: string): TSQLCategory;
  published
    property Items: TSQLCategories read FItems write SetItems;
  end;

  TSQLCategories = class(TSortableCollection)
  private
    function GetSQLCategory(Index: Integer): TSQLCategory;
    function GetSQLCategoryByName(ASQLCategoryName: string): TSQLCategory;
  public
    function Add(const ASQLCategoryName: string): TSQLCategory;
    property SQLCategory[Index: Integer]: TSQLCategory read GetSQLCategory;
    property SQLCategoryByName[ASQLCategoryName: string]: TSQLCategory read GetSQLCategoryByName; default;
  end;

  TSQLCategory = class(TCollectionItem)
  private
    FName: string;
    FSQLItems: TSQLItems;
    procedure SetSQLItems(const Value: TSQLItems);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
  published
    property Name: string read FName write FName;
    property SQLItems: TSQLItems read FSQLItems write SetSQLItems;
  end;

  TSQLItems = class(TSortableCollection)
  private
    function GetSQLItem(Index: Integer): TSQLItem;
    function GetSQLItemByName(ASQLItemName: string): TSQLItem;
  public
    function Add(const ASQLItemName: string): TSQLItem; overload;
    property SQLItem[Index: Integer]: TSQLItem read GetSQLItem;
    property SQLItemByName[ASQLItemName: string]: TSQLItem read GetSQLItemByName; default;
  end;

  TSQLItem = class(TCollectionItem)
  private
    FName: string;
    FSQL: TStrings;
    FLastModifiedQuery: TDateTime;
    procedure SetSQL(const Value: TStrings);
    function GetCategory: string;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
  published
    property Category: string read GetCategory;
    property Name: string read FName write FName;
    property SQL: TStrings read FSQL write SetSQL;
    property LastModifiedQuery: TDateTime read FLastModifiedQuery;
  end;

  ESQLCollectionException = class(Exception);

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('SQLCollection', [TSQLCollection]);
end;

{ TSQLCollection }

constructor TSQLCollection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TSQLCategories.Create(Self, TSQLCategory);
end;

destructor TSQLCollection.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TSQLCollection.FindSQL(const ASQLItemName, ASQLCategoryName: string): string;
var
  LSQLItem: TSQLItem;
begin
  LSQLItem := FindSQLItem(ASQLItemName, ASQLCategoryName);

  if not Assigned(LSQLItem) then
    raise ESQLCollectionException.CreateFmt('SQLItem "%s" of SQLCategory "%s" not found.',
      [ASQLItemName, ASQLCategoryName]);

  Result := LSQLItem.SQL.Text;
end;

function TSQLCollection.FindSQLCategory(const ASQLCategoryName: string): TSQLCategory;
begin
  Result := Items[ASQLCategoryName];
end;

function TSQLCollection.FindSQLItem(const ASQLItemName, ASQLCategoryName: string): TSQLItem;
var
  LSQLCategory: TSQLCategory;
begin
  Result := nil;
  LSQLCategory := FindSQLCategory(ASQLCategoryName);
  if Assigned(LSQLCategory) then
    Result := LSQLCategory.SQLItems[ASQLItemName];
end;

procedure TSQLCollection.SetItems(const Value: TSQLCategories);
begin
  FItems.Assign(Value);
end;

{ TSQLCategories }

function TSQLCategories.Add(const ASQLCategoryName: string): TSQLCategory;
begin
  Result := TSQLCategory.Create(Self);
  Result.Name := ASQLCategoryName;
  Self.Sort;
end;

function TSQLCategories.GetSQLCategory(Index: Integer): TSQLCategory;
begin
  Result := Items[Index] as TSQLCategory;
end;

function TSQLCategories.GetSQLCategoryByName(ASQLCategoryName: string): TSQLCategory;
var
  LIndex: Integer;
begin
  Result := nil;
  if BinarySearch(ASQLCategoryName, LIndex) then
  begin
    Result := GetSQLCategory(LIndex);
  end;
end;

{ TSQLCategory }

constructor TSQLCategory.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FSQLItems := TSQLItems.Create(Self, TSQLItem);
end;

destructor TSQLCategory.Destroy;
begin
  FSQLItems.Free;
  inherited Destroy;
end;

function TSQLCategory.GetDisplayName: string;
begin
  Result := FName;

  if Result.IsEmpty then
    Result := inherited GetDisplayName;
end;

procedure TSQLCategory.SetSQLItems(const Value: TSQLItems);
begin
  FSQLItems.Assign(Value);
end;

{ TSQLItems }

function TSQLItems.Add(const ASQLItemName: string): TSQLItem;
begin
  Result := TSQLItem.Create(Self);
  Result.Name := ASQLItemName;
  Self.Sort;
end;

function TSQLItems.GetSQLItem(Index: Integer): TSQLItem;
begin
  Result := Items[Index] as TSQLItem;
end;

function TSQLItems.GetSQLItemByName(ASQLItemName: string): TSQLItem;
var
  LIndex: Integer;
begin
  Result := nil;
  if BinarySearch(ASQLItemName, LIndex) then
  begin
    Result := GetSQLItem(LIndex);
  end;
end;

{ TSQLItem }

procedure TSQLItem.AfterConstruction;
begin
  inherited;
  FLastModifiedQuery := Now;
end;

constructor TSQLItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FSQL := TStringList.Create;
end;

destructor TSQLItem.Destroy;
begin
  FSQL.Free;
  inherited;
end;

function TSQLItem.GetCategory: string;
begin
  Result := (Self.Collection.Owner as TSQLCategory).Name;
end;

function TSQLItem.GetDisplayName: string;
begin
  Result := FName;

  if Result.IsEmpty then
    Result := inherited GetDisplayName;
end;

procedure TSQLItem.SetSQL(const Value: TStrings);
begin
  FSQL.Assign(Value);
  FLastModifiedQuery := Now;
end;

end.
