//
//  OnlineViewController.m
//  DouYU
//
//  Created by Alesary on 15/10/29.
//  Copyright © 2015年 Alesary. All rights reserved.
//

#import "OnlineViewController.h"
#import "ZWCollectionViewFlowLayout.h"
#import "FourCollectionCell.h"
#import "NetworkSingleton.h"
#import "OnlineModel.h"
#import "MJExtension.h"
#import "MJRefresh.h"

#define URL @"http://www.douyutv.com/api/v1/live?aid=ios&auth=b317487532542c2f8200f374f3153da2&client_sys=ios&limit=20&time=1446684180"

#define URL_offset @"0"
#define URL_time @"time=1446684180"


#define URLHead @"http://www.douyutv.com/api/v1/live/"
#define URLParameter @"?&auth=57d96c66116afaada1d7e471c0949d97&limit=20&client_sys=ios&aid=ios"
static NSString *cellIdentifier = @"OnlineViewCell";


@interface OnlineViewController ()<UICollectionViewDataSource, UICollectionViewDelegate,ZWwaterFlowDelegate>
{
    UICollectionView *_collectionView;
    
    NSMutableArray *_dataArray;
    
    ZWCollectionViewFlowLayout *_flowLayout;//自定义layout
    
    int times; //记录上拉的次数
    
    ColumnModel *_model;
    NSString *_urlStr;
}


@end

@implementation OnlineViewController

- (instancetype)initWithColumnModel:(ColumnModel *)model{
    if (self = [super init]) {
        _model = model;
    }
    return self;
}

- (void)initNavigationItem{
    if (_model == nil) {
        [super initNavigationItem];
        _urlStr = URL;
      
    }else{
        self.title = _model.game_name;
        _urlStr = [NSString stringWithFormat:@"%@%@%@&time=%@",URLHead,_model.cate_id,URLParameter,URL_time];
        UIButton *leftbutton=[UIButton buttonWithType:UIButtonTypeCustom];
        [leftbutton setImage: [UIImage imageNamed:@"btn_nav_back"] forState:UIControlStateNormal];
        [leftbutton setImage: [UIImage imageNamed:@"btn_nav_back_click"] forState:UIControlStateSelected];
        leftbutton.frame=CGRectMake(0, 0, 25, 25);
        [leftbutton addTarget:self action:@selector(btnClickBack) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithCustomView:leftbutton];
    }
    
}

- (void)btnClickBack{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    times=0;
    [self loadData];
    self.view.backgroundColor=[UIColor whiteColor];
    [self initCollectionView];
    [self initMJRefresh];
 
}

-(void)loadData
{
   
    [[NetworkSingleton sharedManager] getResultWithParameter:nil url:[NSString stringWithFormat:@"%@&offset=%@",_urlStr,URL_offset] successBlock:^(id responseBody) {
        
        _dataArray=[OnlineModel objectArrayWithKeyValuesArray:[responseBody objectForKey:@"data"]];
        
        [_collectionView reloadData];
       
    } failureBlock:^(NSString *error) {
    
        
    }];
    
}

-(void)initMJRefresh
{
    
    _collectionView.header=[MJRefreshNormalHeader headerWithRefreshingBlock:^{
        
        [[NetworkSingleton sharedManager] getResultWithParameter:nil url:_urlStr successBlock:^(id responseBody) {
            
            _dataArray=[OnlineModel objectArrayWithKeyValuesArray:[responseBody objectForKey:@"data"]];
            
            [_collectionView reloadData];
            [_collectionView.header endRefreshing];
            
        } failureBlock:^(NSString *error) {
            
            [_collectionView.header endRefreshing];
            [_collectionView.footer resetNoMoreData];
        }];

        
    }];
    
     [_collectionView.header beginRefreshing];
   
    
    _collectionView.footer=[MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        
        times+=20;
        NSString *time=[NSString stringWithFormat:@"%d",times];
       
        [[NetworkSingleton sharedManager] getResultWithParameter:nil url:[NSString stringWithFormat:@"%@&offset=%@",_urlStr,time]  successBlock:^(id responseBody) {
            
            NSArray *array=[OnlineModel objectArrayWithKeyValuesArray:[responseBody objectForKey:@"data"]];
            if (array.count >0) {
                for (OnlineModel *moreData in array) {
                    
                    [_dataArray addObject:moreData];
                }
                
                [_collectionView reloadData];
                [_collectionView.footer endRefreshing];
            }else{
                times -= 20;
                [_collectionView.footer endRefreshingWithNoMoreData];
               // [_collectionView.footer noticeNoMoreData];
            }
            
        } failureBlock:^(NSString *error) {
            
            [_collectionView.footer endRefreshing];
        }];

    }];
    
    _collectionView.footer.hidden = YES;

}

-(void)initCollectionView
{
    //初始化自定义layout
    _flowLayout = [[ZWCollectionViewFlowLayout alloc] init];
    _flowLayout.colMagrin = 5;
    _flowLayout.rowMagrin = 5;
    _flowLayout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    _flowLayout.colCount = 2;
    _flowLayout.degelate = self;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout: _flowLayout];
    //注册显示的cell的类型
    
    UINib *cellNib=[UINib nibWithNibName:@"FourCollectionCell" bundle:nil];
    [_collectionView registerNib:cellNib forCellWithReuseIdentifier:cellIdentifier];
    
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor=RGBA(200, 200, 200, 0.25);
    [self.view addSubview:_collectionView];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //重用cell
    FourCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];

    cell.onlineData=_dataArray[indexPath.item];
    return cell;
}
#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"你点击了 %ld--%ld",(long)indexPath.section,indexPath.item);
}


#pragma mark ZWwaterFlowDelegate
- (CGFloat)ZWwaterFlow:(ZWCollectionViewFlowLayout *)waterFlow heightForWidth:(CGFloat)width atIndexPath:(NSIndexPath *)indexPach
{
    
    return 150*KWidth_Scale;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
