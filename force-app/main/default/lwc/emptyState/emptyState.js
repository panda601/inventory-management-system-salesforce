import { LightningElement, api } from 'lwc';

export default class EmptyState extends LightningElement {
    @api title = 'No Data Found';
    @api message = 'There are no records to display in this list.';
    @api iconName = 'utility:database';
}