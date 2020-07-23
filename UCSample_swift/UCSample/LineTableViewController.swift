//
//  LineTableViewController.m
//  UCSample
//
//  Created by Joe Lepple on 7/11/14.
//  Copyright (c) 2014 PortSIP Solutions, Inc. All rights reserved.
//

protocol LineViewControllerDelegate {
    func didSelectLine(_ activeLine: Int)
}

class LineTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var activeLine: Int!
    var delegate: LineViewControllerDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations.
        // self.clearsSelectionOnViewWillAppear = NO;

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // #pragma mark - Table view data source
    func numberOfSections(in _: UITableView) -> Int {
        // Return the number of sections.
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        // Return the number of rows in the section.
        8
    }

    /// *

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LineCell", for: indexPath as IndexPath)

        // Configure the cell...
        cell.textLabel!.text = String(format: "Line -%d", indexPath.row)
        if indexPath.row == activeLine {
            cell.accessoryType = UITableViewCell.AccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCell.AccessoryType.none
        }
        return cell
    }

    // */

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Navigation logic may go here. Create and push another view controller.
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)

        delegate.didSelectLine(indexPath.row)
    }

    /*
     // Override to support conditional editing of the table view.
     - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
     {
     // Return NO if you do not want the specified item to be editable.
     return YES;
     }
     */

    /*
     // Override to support editing the table view.
     func tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
     {
     if (editingStyle == UITableViewCellEditingStyleDelete) {
     // Delete the row from the data source
     [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade);
     } else if (editingStyle == UITableViewCellEditingStyleInsert) {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */

    /*
     // Override to support rearranging the table view.
     func tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
     {
     }
     */

    /*
     // Override to support conditional rearranging of the table view.
     - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
     {
     // Return NO if you do not want the item to be re-orderable.
     return YES;
     }
     */

    /*
     #pragma mark - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     func prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
     {
     // Get the new view controller using [segue destinationViewController].
     // Pass the selected object to the new view controller.
     }
     */
}
