//
//  MenuTable.m
//  Bruin Dining
//
//  Created by Mahir Eusufzai on 4/2/14.
//  Copyright (c) 2014 Mahir Eusufzai. All rights reserved.
//

#import "MenuTableController.h"

const int PREFERENCE_TRANSLATION_HEIGHT = 120;
@interface MenuTableController ()

@end

@implementation MenuTableController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
         
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        _currentMeal = MealTypeUnknown;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    initialTablePosition = _table.frame.origin;
    menuIsLoading = false;
    
    _summarySwitch.on = ([self summaryPreference] == specificitySummary);
    _vegSwitch.on = ([self getVegPreference] != VegPrefAll);

    if (_currentMeal != MealTypeUnknown){
        [self.navigationItem setTitle:[MealTypes stringForMealType:_currentMeal]];
    }
    

    //gesture setup
    UISwipeGestureRecognizer * swipeleft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeleft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeleft];
    
    UISwipeGestureRecognizer * swiperight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swiperight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swiperight];
    
    [self.navigationItem setHidesBackButton:YES];

    [self setCurrentMenu];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key =  [self.hallSelector.sectionTitles objectAtIndex:self.hallSelector.selectedSegmentIndex];
    Station *s = [currentMenu getStation:section ForHall:key];
    return [s foodListForVegPref:[self getVegPreference]].count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSString *key =  [self.hallSelector.sectionTitles objectAtIndex:self.hallSelector.selectedSegmentIndex];
    DiningHall *d = [currentMenu.hallList valueForKey:key];
    return d.stationList.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSString *key =  [self.hallSelector.sectionTitles objectAtIndex:self.hallSelector.selectedSegmentIndex];
    Station *s = [currentMenu getStation:section ForHall:key];
    return s.name;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    MenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell"];
    
    if (!cell){
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"MenuCell" owner:self options:nil];
        cell = (MenuCell *)[nib objectAtIndex:0];
    }
    
    NSString *key =  [self.hallSelector.sectionTitles objectAtIndex:self.hallSelector.selectedSegmentIndex];
    Station *s = [currentMenu getStation:indexPath.section ForHall:key];
    MenuItem* food = [[s foodListForVegPref:[self getVegPreference]] objectAtIndex:indexPath.row];
    cell.menuItem = food;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    return 25;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 50;
}
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    
    view.tintColor = [UIColor colorWithRed:233/255.0f green:181/255.0f blue:41/255.0f alpha:1];
    // if you have index/header text in your tableview change your index text color
    UITableViewHeaderFooterView *headerIndexText = (UITableViewHeaderFooterView *)view;
    [headerIndexText.textLabel setTextColor:[UIColor blackColor]];
    [headerIndexText.textLabel setFont: [UIFont fontWithName:@"Helvetica Light" size:14]];
    
    
}

#pragma mark -- segmented control
- (void)switchHall {
    
    _hallName.text = [self.hallSelector.sectionTitles objectAtIndex:self.hallSelector.selectedSegmentIndex];
    
    [self setOpeningClosingTimes];
    [self.table reloadData];
}



# pragma mark -- helper functions
- (void) setCurrentMenu {
    
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        self.table.hidden = NO;
        UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Connection Error"
                                                         message:@"Cannot connect to internet. Close app and try again later."
                                                        delegate:self
                                               cancelButtonTitle:nil
                                               otherButtonTitles: nil];
        [alert addButtonWithTitle:@"Ok"];
        [alert show];
        return;
    }
    
    menuIsLoading = TRUE;
    //hide table while loading data
    self.table.hidden=YES;
    self.summarySwitch.hidden = YES;
    self.vegSwitch.hidden = YES;
    _summaryLabel.hidden = YES;
    _vegLabel.hidden = YES;
    _hideSettingsButton.hidden = YES;
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        MenuLoader *ml = [[MenuLoader alloc] init];
        currentMenu = [ml mealForType:_currentMeal Specificity:[self summaryPreference]];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.spinner stopAnimating];
            self.table.hidden = NO;
            _vegSwitch.hidden = NO;
            _summarySwitch.hidden = NO;
            _vegLabel.hidden = NO;
            _summaryLabel.hidden = NO;
            _hideSettingsButton.hidden = NO;
            [self.navigationItem setTitle:currentMenu.name];
            [self setHours];
            [self showSwipeTutorialIfNeeded];
            [self.table reloadData];
            menuIsLoading = false;
            
        });
    });
    
}

-(void) setHours {
    
    NSArray *halls = [currentMenu.hallList allValues];
    NSMutableArray *hallNames = [NSMutableArray array];
    NSMutableArray *hallImages = [NSMutableArray array];
    UIImage *open = [UIImage imageNamed:@"open.png"];
    UIImage *closed = [UIImage imageNamed:@"closed.png"];
    
    for (DiningHall* hall in halls){
        [hallNames addObject:hall.name];
        [hallImages addObject:(hall.isOpen ? open :closed)];
        
    }
    
    self.hallSelector.sectionTitles = hallNames;
    self.hallSelector.type = HMSegmentedControlTypeTextImages;
    self.hallSelector.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    self.hallSelector.font = [UIFont fontWithName:@"Helvetica Light" size:13];
    self.hallSelector.backgroundColor = [UIColor colorWithRed:233/256.0 green:233/256.0 blue:233/256.0  alpha:1];
    
    self.hallSelector.sectionImages =  hallImages;
    self.hallSelector.sectionSelectedImages = self.hallSelector.sectionImages;
    self.hallSelector.selectionStyle = HMSegmentedControlSelectionStyleTextWidthStripe;
    [self.hallSelector addTarget:self action:@selector(switchHall) forControlEvents:UIControlEventValueChanged];
    
    self.hallName.text = [self.hallSelector.sectionTitles objectAtIndex:self.hallSelector.selectedSegmentIndex];
    [self.hallSelector setNeedsDisplay];
    [self setOpeningClosingTimes];
    
}

- (void) setOpeningClosingTimes {
    
    DiningHall *currHall = [currentMenu.hallList valueForKey:_hallName.text];
    
    if ([currHall isOpen]){
        NSInteger time = [currHall getTimeUntilCloses];
        self.timeLabel.text = [NSString stringWithFormat:@"Closes in %d hours %d minutes", time/3600, (time/60) %60];
    }
    else{
        NSInteger time = [currHall getTimeUntilOpens];
        if (time<0) //hall isn't open for current or subsequent meal
            self.timeLabel.text = [NSString stringWithFormat:@"Closed for %@", currentMenu.name];
        else
            self.timeLabel.text = [NSString stringWithFormat:@"Opens in %d hours %d minutes", time/3600, (time/60) %60];
    }
}

-(void)swipeleft:(UISwipeGestureRecognizer*)gestureRecognizer
{
    if ([self preferencesVisible])
        return; //temporary fix so that swiping uiswitch doesn't trigger function
    [self disableTutorial];
    //TO DO: Temporary fix, menutype isn't updated until loading finishes
    //MealType curMeal = ((menuIsLoading && currentMenu.type == MealTypeUnknown) ? currentMenu.type + 1 : currentMenu.type);
    MealType curMeal = currentMenu.type;
    int newMeal = [MenuLoader MealAfterMeal:curMeal];
    //NSLog(@"%d", newMeal);
    if (newMeal == -1)
        return;
    MenuTableController *newMenu = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    newMenu.currentMeal = newMeal;
    [self.navigationController pushViewController:newMenu animated:YES];
}

-(void)swiperight:(UISwipeGestureRecognizer*)gestureRecognizer
{
    if ([self preferencesVisible])
        return; //temporary fix so that swiping uiswitch doesn't trigger function
    [self disableTutorial];
    //TO DO: Temporary fix, menutype isn't updated until loading finishes
    //MealType curMeal = ((menuIsLoading && currentMenu.type == MealTypeUnknown) ? currentMenu.type - 1 : currentMenu.type);
    MealType curMeal = currentMenu.type;
    int newMeal = [MenuLoader MealBeforeMeal:curMeal];
    //NSLog(@"%d", newMeal);

    if (newMeal == -1)
        return;
    
    MenuTableController *newMenu = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    newMenu.currentMeal = newMeal;
    NSMutableArray *vcs =  [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [vcs insertObject:newMenu atIndex:[vcs count]-1];
    [self.navigationController setViewControllers:vcs animated:NO];
    [self.navigationController popViewControllerAnimated:YES];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -- veg preferences

-(VegPreference)getVegPreference {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *pref = [defaults stringForKey:@"vegPref"];
    
    if (!pref) {
        [defaults setObject:[NSNumber numberWithInt:VegPrefAll] forKey:@"vegPref"];
        [defaults synchronize];
    }
    
    return [[defaults objectForKey:@"vegPref"]intValue];
}

- (Specificity)summaryPreference {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *pref = [defaults stringForKey:@"summaryPref"];
    
    if (!pref) {
        [defaults setObject:[NSNumber numberWithInt:specificitySummary] forKey:@"summaryPref"];
        [defaults synchronize];
    }
    
    return [[defaults objectForKey:@"summaryPref"]intValue];

}
-(void) vegPrefChanged {
    NSLog(@"before %@", NSStringFromCGRect(_table.frame));
    [_table reloadData];
    _table.frame = CGRectMake(initialTablePosition.x, initialTablePosition.y+PREFERENCE_TRANSLATION_HEIGHT, _table.frame.size.width, _table.frame.size.height);
    NSLog(@"after %@", NSStringFromCGRect(_table.frame));

}

- (void) changeVegPref:(id)sender {
    UISwitch *s = (UISwitch*)sender;
    VegPreference pref = (s.isOn ? VegPrefVegetarian : VegPrefAll);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:pref] forKey:@"vegPref"];
    [defaults synchronize];
    [self vegPrefChanged];
    
}

- (void)changeSummaryPref:(id)sender {
    
    UISwitch *s = (UISwitch*)sender;
    currentSpec = s.isOn ? specificitySummary : specificityExplicit;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:currentSpec] forKey:@"summaryPref"];
    [defaults synchronize];
    [self setCurrentMenu];
    
}
- (void)togglePreferencePageVisibility:(id)sender {
    int translation = [self preferencesVisible] ? -PREFERENCE_TRANSLATION_HEIGHT :    PREFERENCE_TRANSLATION_HEIGHT;
   
    //animate tableview down
    [UIView animateWithDuration:0.3
                          delay:0
                        options: UIViewAnimationCurveEaseOut
                     animations:^{
                         _table.center = CGPointMake(_table.center.x, _table.center.y+translation);
                     }
                     completion:^(BOOL finished){
                         
                     }];
}

- (void) showSwipeTutorialIfNeeded {
    
    //determine if needed
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL shouldSet = [[defaults objectForKey:@"needsSwipeTutorial"] boolValue];
    if (shouldSet) {
        
            //ios7
            UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Tutorial"
                                                             message:@"Swipe left and right to change meals."
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles: nil];
            [alert addButtonWithTitle:@"Got it!"];
            [alert show];
        
        
    }
    
}

-(void)disappearTheView {
    
    [UIView animateWithDuration:.5
                          delay:10.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^{
                         _tutorial.alpha = 0;
                     }
                     completion:NULL];
}
- (void)disableTutorial {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:false] forKey:@"needsSwipeTutorial"];
    
}

# pragma mark -- iAD delegate

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    
    
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
}


- (BOOL)preferencesVisible {
    
    return _table.frame.origin.y > initialTablePosition.y;
}
@end
