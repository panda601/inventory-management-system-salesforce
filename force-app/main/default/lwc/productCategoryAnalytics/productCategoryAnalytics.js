import { LightningElement, wire, track } from 'lwc';
import getMonitorData from '@salesforce/apex/InventoryController.getMonitorData';

export default class ProductCategoryAnalytics extends LightningElement {
    @track chartData = [];
    error;

    @wire(getMonitorData)
    wiredData(result) {
        if (result.data) {
            const counts = {};
            result.data.forEach(p => {
                const cat = p.Category__c || 'Other';
                counts[cat] = (counts[cat] || 0) + (p.Current_Stock__c || 0);
            });
            
            // Map labels to align with requirements
            const labels = {
                'Electronics': 'Laptops',
                'Apparel': 'Accessories',
                'Food': 'Peripherals',
                'Home': 'Monitors',
                'Other': 'General'
            };
            
            const maxVal = Math.max(...Object.values(counts), 1);
            
            this.chartData = Object.keys(counts).map(key => {
                const val = counts[key];
                const pct = Math.round((val / maxVal) * 100);
                
                // Colors
                let colorClass = 'bar-fill primary';
                if (key === 'Electronics') colorClass = 'bar-fill laptops';
                else if (key === 'Home') colorClass = 'bar-fill monitors';
                else if (key === 'Apparel') colorClass = 'bar-fill accessories';
                else if (key === 'Food') colorClass = 'bar-fill peripherals';

                return {
                    category: key,
                    label: labels[key] || key,
                    value: val,
                    pct,
                    colorClass,
                    heightStyle: `height: ${pct > 10 ? pct : 12}%;`
                };
            });
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.chartData = [];
        }
    }

    get hasData() {
        return this.chartData.length > 0;
    }
}
